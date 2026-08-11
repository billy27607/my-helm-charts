# Ubuntu Netboot

A PXE/TFTP boot server for installing Ubuntu Server over the network. Point a
machine's NIC at network boot and it loads the official Ubuntu Server
installer straight from your LAN - no USB stick required.

## How It Works

The chart runs a `dnsmasq` TFTP server (DHCP and DNS disabled) that serves
Canonical's official netboot bundle - the bootloader (`pxelinux.0` for BIOS,
`bootx64.efi` for UEFI), kernel, and initrd. On every pod start it checks
`releases.ubuntu.com` for the latest point release under the configured
`ubuntu.release` track and downloads it only if it's new; the files are
cached on a persistent volume so restarts don't re-download ~100MB every
time.

Once a client PXE-boots the installer, it downloads the actual install ISO
directly from `releases.ubuntu.com` over the internet - this chart does not
mirror the ISO itself.

This chart intentionally does **not** run a DHCP server. It relies on your
existing router/DHCP server to point PXE clients at it, which avoids any
risk of conflicting with DHCP already running on your network.

## Prerequisites

- A single-node (or node-pinned) cluster with `hostNetwork` support - the
  boot server must be reachable at a real LAN IP for PXE/TFTP to work.
- Access to your router/DHCP server's configuration to set the PXE boot
  options (see below).
- Outbound internet access from both the cluster node (to fetch the netboot
  bundle) and the client machine being installed (to fetch the install ISO).

## Install

```bash
helm install ubuntu-netboot ./charts/ubuntu-netboot \
  --namespace netboot \
  --create-namespace
```

Find the node IP the pod landed on - this is the address you'll point your
router at:

```bash
kubectl get pods -n netboot -o wide
```

## Configure Your Router's DHCP Options

Point PXE clients at this server by setting on your router/DHCP server:

- **Option 66 (next-server / TFTP server name)**: the node IP from above
- **Option 67 (bootfile-name)**:
  - `pxelinux.0` for legacy BIOS clients
  - `bootx64.efi` for UEFI clients (most modern hardware)

Most consumer routers don't expose options 66/67 directly - you may need a
custom DHCP server (dnsmasq, pfSense, OPNsense, Unifi's "Network" app under
advanced DHCP settings, etc.) or a Windows/Linux DHCP server with vendor
class options configured.

## Boot a Client

1. Set the target machine to network boot (usually F12/F11/Esc/Del at
   startup, or set PXE boot first in BIOS/UEFI boot order).
2. It should pick up the bootloader from this server and load straight into
   the Ubuntu Server installer.
3. Complete the installer as normal - this is a stock, interactive install;
   the chart doesn't alter or automate the install itself.

## Configuration

| Value | Description | Default |
|-------|-------------|---------|
| `ubuntu.release` | Ubuntu major.minor track to serve (e.g. `24.04`, `22.04`) | `24.04` |
| `ubuntu.netbootUrlOverride` | Skip auto-discovery and use this netboot tarball URL directly | `""` |
| `interface` | Restrict the TFTP server to one host NIC | `""` (all interfaces) |
| `persistence.hostPath` | Where the boot files are cached on the node | `/var/lib/ubuntu-netboot` |
| `hostNetwork` | Required for PXE clients to reach the pod at the node IP | `true` |

Pin a different Ubuntu release:

```bash
helm upgrade ubuntu-netboot ./charts/ubuntu-netboot \
  --namespace netboot \
  --set ubuntu.release=22.04
```

## Troubleshooting

**Client doesn't find the boot server**: double check DHCP options 66/67 on
your router match the node IP and bootloader filename, and that the client
and this pod are on the same broadcast domain/VLAN (TFTP over PXE doesn't
route across subnets without a DHCP relay).

**Check what version is currently served**:
```bash
kubectl exec -n netboot deploy/ubuntu-netboot -- cat /srv/tftp/.netboot-version
```

**Watch startup/download logs**:
```bash
kubectl logs -n netboot -l app.kubernetes.io/name=ubuntu-netboot -f
```

**Force a re-download** (e.g. after a corrupted cache):
```bash
kubectl exec -n netboot deploy/ubuntu-netboot -- rm /srv/tftp/.netboot-version
kubectl rollout restart -n netboot deployment/ubuntu-netboot
```
