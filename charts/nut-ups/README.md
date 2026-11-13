# nut-ups

[Network UPS Tools](https://networkupstools.org/) for a USB-attached UPS (default: APC Back-UPS Pro BR1500MS2), with graceful shutdown of the node it runs on and of any equipment on the LAN.

## What it does

One pod, on the node the UPS's USB data cable is plugged into:

| Process | Role |
|---|---|
| `usbhid-ups` | Talks to the UPS over USB |
| `upsd` | NUT server on `<node-ip>:3493` (host network) for other equipment |
| `upsmon` (primary) | Runs the shutdown sequence |
| `nut_exporter` sidecar | Prometheus metrics on `:9199/ups_metrics` |

### Shutdown sequence

1. Power fails, so the UPS goes **OB** (on battery). Nothing happens yet.
2. Battery drops to **≤ 30%** *or* the estimated runtime falls to **≤ 300 s**. The driver ignores the UPS's own (too late) low-battery flag and uses these thresholds. Optionally, set `shutdown.onBatteryTimeout` to shut down after N seconds on battery regardless.
3. `upsmon` raises **FSD**. Every LAN client (NAS, PCs, …) sees it and shuts itself down.
4. The primary waits up to `hostSync` (60 s) for the clients to disconnect.
5. It tells the UPS to cut outlet power after `offDelay` (300 s) and **turn it back on when mains returns**. It tries `shutdown.return`, then `shutdown.reboot`, then `load.off.delay`. The BR1500MS2 doesn't support `shutdown.return`, so it uses `shutdown.reboot`, which also briefly cycles the outlets if power came back mid-shutdown.
6. It runs `systemctl poweroff` on the node through `nsenter` (`hostPID` + privileged).

For equipment to come back up after the outage, set the BIOS option "Restore on AC power loss" to **Power On** on each machine.

## Install

```bash
# Build the image (VS Code task "docker: Build nut-ups", tag 1.0.0), then either
# push it (task "docker: Push nut-ups"; make the ghcr package public) or side-load it:
docker save ghcr.io/billy27607/nut-ups:1.0.0 | ssh bsmart 'sudo k3s ctr images import -'

scripts/k8s-helpers.sh helm-install nut-ups nut-ups --namespace=ups
```

Try it with `--set shutdown.dryRun=true` first. Then simulate an outage by pulling the UPS's wall plug: logs should show `ONBATT`, and when the battery reaches the threshold, the dry-run shutdown. Delete the pod to clear the FSD state.

```bash
scripts/k8s-helpers.sh helm-logs nut-ups --namespace=ups
kubectl -n ups exec deploy/nut-ups -c nut -- upsc ups@localhost   # all UPS variables
```

## Push notifications

`notifications.provider` is `pushover` (default) or `ntfy`.

| Event | ntfy priority | Pushover priority |
|---|---|---|
| Battery low (shutdown starting), monthly self-test failed | urgent | **emergency**: repeats every 60 s until acknowledged |
| Power outage, shutting down, powering off host, replace battery, lost contact with UPS | high | high |
| Power restored | default | normal |
| Self-test passed, monitor started (e.g. after a reboot), UPS contact restored | low | low (no sound) |

**Pushover:** create an account in the iOS app, then create an application at <https://pushover.net/apps/build>. Pass the keys once; they're saved in the release Secret:

```bash
scripts/k8s-helpers.sh helm-upgrade nut-ups nut-ups --namespace=ups \
  --set notifications.pushover.userKey=<user key> --set notifications.pushover.apiToken=<api token>
```

In the Pushover app, enable **Critical Alerts** so emergency alerts sound even in Silent mode or Do Not Disturb.

**ntfy:** `--set notifications.provider=ntfy`, then subscribe in the ntfy app to the auto-generated topic (`kubectl -n ups get secret nut-ups -o jsonpath='{.data.ntfy-topic}' | base64 -d`). Anyone who knows the topic can read the alerts.

Alerts during an outage only arrive if your internet equipment (modem/ONT) is also on the UPS.

The self-test CronJob runs `test.battery.start.quick` (about 10 s on battery) at 11:00 on the 1st of each month. To run one now:

```bash
kubectl -n ups create job --from=cronjob/nut-ups-selftest selftest-manual
```

## Connecting other equipment

Each device runs a NUT client in **secondary** mode against `ups@192.168.100.25` (bsmart).

```bash
kubectl -n ups get secret nut-ups -o jsonpath='{.data.monitor-password}' | base64 -d
```

**Linux** (`apt install nut-client`). In `/etc/nut/nut.conf`, set `MODE=netclient`. In `/etc/nut/upsmon.conf`:

```
MONITOR ups@192.168.100.25 1 monuser <monitor-password> secondary
SHUTDOWNCMD "/sbin/shutdown -h +0"
```

**Synology DSM**: Control Panel → Hardware & Power → UPS → *Synology UPS server* / *Network UPS* → server `192.168.100.25`. DSM hardcodes `monuser`/`secret`, so install with `--set auth.monitorPassword=secret`.

**TrueNAS / Unraid / Proxmox / Home Assistant (NUT integration)**: remote/netclient mode, host `192.168.100.25`, port `3493`, UPS `ups`, user `monuser`.

Windows: [WinNUT-Client](https://github.com/nutdotnet/WinNUT-Client).

## Key values

| Value | Default | |
|---|---|---|
| `shutdown.batteryChargeLow` | `30` | % at which shutdown starts (while on battery) |
| `shutdown.batteryRuntimeLow` | `300` | Runtime seconds at which shutdown starts |
| `shutdown.onBatteryTimeout` | `0` | Shut down after N s on battery (0 = off) |
| `shutdown.hostSync` | `60` | Seconds to wait for LAN clients |
| `shutdown.killPower` | `true` | Power-cycle the UPS outlets so everything reboots |
| `shutdown.offDelay` / `onDelay` | `300` / `360` | UPS power-off delay; `onDelay` must be > `offDelay` |
| `shutdown.dryRun` | `false` | Log only; don't cut power or power off the host |
| `auth.monitorPassword` | generated | Password for LAN clients (`monuser`) |
| `notifications.provider` | `pushover` | `pushover` or `ntfy` |
| `selfTest.schedule` | `0 11 1 * *` | Monthly quick battery test |
| `hostNetwork` | `true` | Expose upsd on the node IP for the LAN |

## Notes

- `image.pullPolicy: IfNotPresent` is intentional. After an outage the node may boot before the internet is back.
- If the driver can't find the UPS, the pod logs its USB device list and keeps retrying. If several APC devices are attached, set `ups.productId`.
- The default 300 s `offDelay` must cover the slowest device (a Synology can take several minutes) and the node powering off.
