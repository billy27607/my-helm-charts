# Copilot Instructions for my-helm-charts

## Repository Overview

This is a **home lab Helm charts repository** for deploying smart home and media services on Kubernetes. Charts are hosted on GitHub Pages via chart-releaser-action and designed for single-node edge deployments with hardware device access (USB, GPU, serial devices).

## Architecture Principles

### Edge-First Design
- **Default to `hostNetwork: true`** for IoT/media services needing device discovery (mDNS, SSDP, etc.)
- Services like Scrypted, Homebridge, HDHomeRun proxies, and Mosquitto require direct network access
- Use `hostPath` persistence by default (edge) over PVCs (cluster)
- `type: Recreate` deployment strategy to prevent port conflicts on single-node setups

### Hardware Device Patterns
Charts expose host devices via `volumeMounts`:
```yaml
devices:
  usb: false          # /dev/bus/usb for Coral TPU
  dri: false          # /dev/dri for Intel QSV/hardware transcoding
  kfd: false          # /dev/kfd for AMD GPU
  serial:             # List serial devices
    - /dev/ttyACM0    # Z-Wave/Zigbee USB controllers
  extra:              # Additional character devices
    - /dev/apex_0     # Google Coral PCIe TPU
```
Requires `securityContext.privileged: true` for device access.

**Template pattern for device mounting:**
```yaml
volumeMounts:
  {{- if .Values.devices.usb }}
  - name: usb
    mountPath: /dev/bus/usb
  {{- end }}
  {{- range .Values.devices.serial }}
  - name: {{ . | base | lower | replace "." "-" }}
    mountPath: {{ . }}
  {{- end }}
volumes:
  {{- if .Values.devices.usb }}
  - name: usb
    hostPath:
      path: /dev/bus/usb
  {{- end }}
  {{- range .Values.devices.serial }}
  - name: {{ . | base | lower | replace "." "-" }}
    hostPath:
      path: {{ . }}
  {{- end }}
```

**Common devices in this homelab:**
- **Coral TPU** (USB): `devices.usb: true` for ML object detection in Scrypted
- **Intel QuickSync** (/dev/dri): `devices.dri: true` + `intelGpu.enabled: true` for hardware video transcoding
- **Z-Wave USB** (/dev/ttyACM0): `devices.serial` for Z-Wave JS integration
- **Zigbee USB** (/dev/ttyACM1): Additional serial device for Zigbee coordinators

### Chart Categories
This repository contains three types of charts:

**Single-Service Charts** (most charts): scrypted, iperf3, rtl-sdr, hdhomerun-app-proxy, hdhomerun-tuner-proxy, auto-mount, firefox-remote, prometheus
- One deployment per chart
- Standard `_helpers.tpl` with `<chart>.name`, `<chart>.fullname`, `<chart>.labels`, `<chart>.selectorLabels`

**Multi-Component Charts**: homebridge (Homebridge + Mosquitto), xcarve (CNCjs + MJPG-Streamer)
- Multiple deployments bundled in one chart
- Pattern structure:
  - Separate `deployment-<component>.yaml` and `service-<component>.yaml` templates
  - Conditional enablement via `.<component>.enabled` in values.yaml
  - Component-specific helpers in `_helpers.tpl` (e.g., `homebridge.mosquitto.labels`, `xcarve.cncjs.labels`)
  - Each component has nested values: `.<component>.image`, `.<component>.persistence`, `.<component>.service`

## Development Workflows

### Local Testing with k8s-helpers.sh
**Never use kubectl commands directly** - always use the `scripts/k8s-helpers.sh` wrapper script:

```bash
# Helm workflows (preferred)
scripts/k8s-helpers.sh helm-install scrypted my-release --namespace=ourplan
scripts/k8s-helpers.sh helm-upgrade scrypted my-release --namespace=ourplan --set hostNetwork=false
scripts/k8s-helpers.sh helm-status my-release --namespace=ourplan
scripts/k8s-helpers.sh helm-logs my-release --namespace=ourplan     # Auto-detects pod labels
scripts/k8s-helpers.sh helm-restart my-release --namespace=ourplan  # Rollout restart
scripts/k8s-helpers.sh helm-uninstall my-release --namespace=ourplan

# Direct YAML workflows (legacy - for raw kubectl apply)
scripts/k8s-helpers.sh status deployment.yaml
scripts/k8s-helpers.sh logs deployment.yaml     # Extracts app selector
scripts/k8s-helpers.sh events deployment.yaml
scripts/k8s-helpers.sh resources deployment.yaml
```

**Key features of k8s-helpers.sh:**
- Auto-detects and uninstalls conflicting releases before upgrade (prevents hostPort/hostNetwork conflicts)
- Smart pod label detection (tries `app.kubernetes.io/instance=<release>`, then `app=<selector>`)
- Automatic namespace handling (defaults: "monitoring" for prometheus/headlamp, otherwise requires `--namespace` flag)
- Built-in wait/status checks after install/upgrade operations
- Color-coded output for clarity

### VS Code Tasks
Run via Command Palette → "Run Task" or terminal directly:
- **helm: Install/Upgrade/Status/Logs/Restart/Uninstall** - Helm lifecycle operations
- **k8s: Deploy/Status/Logs/Events/Resource Usage/Teardown** - Direct kubectl operations (legacy)

Tasks automatically:
- Prompt for chart name (pickString from available charts in `.vscode/tasks.json`)
- Prompt for release name and namespace (defaults to "ourplan")
- Support custom Helm args via prompt (e.g., `--set key=value`)
- Pass all inputs to `k8s-helpers.sh` for unified handling

**Task inputs defined in `.vscode/tasks.json`:**
- `chartName`: Hardcoded list: `["homebridge", "iperf3", "rtl-sdr", "hdhomerun-app-proxy", "auto-mount", "hdhomerun-tuner-proxy", "prometheus", "xcarve", "scrypted", "firefox-remote"]`
- `releaseName`: Custom release name (user input)
- `namespace`: Target namespace (default: "ourplan")
- `helmExtraArgs`: Additional flags (e.g., `--set key=value`)

**Important**: When adding a new chart, update the `chartName` pickString options in `.vscode/tasks.json`

## Code Conventions

### Multi-Component Charts Pattern
All charts follow standard Helm helper structure in `_helpers.tpl`:
```go
{{- define "<chart>.name" -}}...{{- end }}
{{- define "<chart>.fullname" -}}...{{- end }}
{{- define "<chart>.labels" -}}...{{- end }}
{{- define "<chart>.selectorLabels" -}}...{{- end }}
```

For multi-component charts (homebridge, xcarve), add component-specific variants:
```go
{{/* homebridge pattern - name suffix in helper */}}
{{- define "homebridge.mosquitto.labels" -}}
helm.sh/chart: {{ include "homebridge.chart" . }}
{{ include "homebridge.mosquitto.selectorLabels" . }}
{{- end }}

{{- define "homebridge.mosquitto.selectorLabels" -}}
app.kubernetes.io/name: {{ include "homebridge.name" . }}-mosquitto
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/* xcarve pattern - component label */}}
{{- define "xcarve.cncjs.labels" -}}
{{ include "xcarve.labels" . }}
app.kubernetes.io/component: cncjs
{{- end }}

{{- define "xcarve.cncjs.selectorLabels" -}}
{{ include "xcarve.selectorLabels" . }}
app.kubernetes.io/component: cncjs
{{- end }}
```

Example multi-component template structure:
```yaml
{{- if .Values.mosquitto.enabled }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "homebridge.fullname" . }}-mosquitto
  labels:
    {{- include "homebridge.mosquitto.labels" . | nindent 4 }}
spec:
  selector:
    matchLabels:
      {{- include "homebridge.mosquitto.selectorLabels" . | nindent 6 }}
...
{{- end }}
```

**Key pattern differences:**
- **homebridge**: Uses name suffix in both helper definition and selectorLabels (e.g., `homebridge.name` → `homebridge.name-mosquitto`)
- **xcarve**: Uses `app.kubernetes.io/component` label added to base labels (both components share base name)

### Values.yaml Organization
Structure by concern, not alphabetically:
1. Image config (`image.repository`, `image.tag`, `image.pullPolicy`)
2. Network mode (`hostNetwork`, `service`)
3. Hardware access (`devices`, `securityContext.privileged`)
4. Persistence (`persistence.type`, `persistence.hostPath`, `nvrStorage`)
5. Resources and scheduling (`resources`, `nodeSelector`, `affinity`)

### Dual Storage Support
Provide both edge and cluster persistence modes:
```yaml
persistence:
  enabled: true
  type: hostPath  # or "pvc"
  hostPath: /var/lib/scrypted
  size: 10Gi
```

Template conditional logic:
```yaml
{{- if .Values.persistence.enabled }}
{{- if eq .Values.persistence.type "hostPath" }}
hostPath:
  path: {{ .Values.persistence.hostPath }}
{{- else }}
persistentVolumeClaim:
  claimName: {{ include "chart.fullname" . }}
{{- end }}
{{- end }}
```

## Troubleshooting Patterns

### hostNetwork Conflicts
**Problem**: "port 10443 already in use" when multiple releases use same chart  
**Solution**: The `helm-upgrade` command auto-detects and uninstalls conflicting releases. Always use release names distinct from chart names.

**How conflict detection works:**
- Before upgrade, `k8s-helpers.sh helm-upgrade` searches all namespaces for other releases using the same chart
- Automatically uninstalls conflicting releases to free hostPort/hostNetwork bindings
- Example: Upgrading `scrypted` chart as release `my-scrypted` will first check for other `scrypted-*` releases and uninstall them

### Device Access Failures
**Required**: `privileged: true` for serial/USB devices  
**Common issue**: Device paths change on reboot (e.g., `/dev/ttyACM0` → `/dev/ttyACM1`)  
**Fix**: Use udev rules or `/dev/serial/by-id/*` paths in `devices.serial`

### Intel GPU Device Plugin
For hardware transcoding (Scrypted, Frigate), install Intel device plugins:
```bash
kubectl apply -k https://github.com/intel/intel-device-plugins-for-kubernetes/deployments/gpu_plugin/overlays/nfd_labeled_nodes
```
Then enable in values: `intelGpu.enabled: true` and `devices.dri: true`

### Metrics Server
Required for `k8s-helpers.sh resources` command:
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

### Persistent Storage
Edge deployments default to `hostPath`. For cluster setups:
1. Create StorageClass for your CSI driver
2. Set `persistence.type: pvc` and `persistence.storageClass: <name>`
3. For NVR recordings, use NFS: `nvrStorage.type: nfs`

## Creating New Charts

### From Scratch
```bash
cd charts/
helm create my-service
# Edit Chart.yaml, values.yaml, templates/
scripts/k8s-helpers.sh helm-install my-service test-release
```

### Migrating from Docker Compose
1. Copy service config from `scrypted-compose.yaml` or similar
2. Create chart structure matching existing single-service charts (scrypted, iperf3) or multi-component charts (homebridge, xcarve)
3. Key translations:
   - `network_mode: host` → `hostNetwork: true`
   - `volumes` → `persistence.hostPath` or `volumeMounts`
   - `devices` → `devices.serial/usb/dri` + `privileged: true`
   - `environment` → `env.extra` array
   - `ports` → `containerPort` (hostNetwork exposes all ports)

### Chart Testing Workflow
```bash
# Install and watch logs
scripts/k8s-helpers.sh helm-install my-chart test-release
scripts/k8s-helpers.sh helm-logs test-release

# Iterate on templates
scripts/k8s-helpers.sh helm-upgrade my-chart test-release --set key=value

# Check status and events
scripts/k8s-helpers.sh helm-status test-release
kubectl get events --sort-by='.lastTimestamp' | tail -20
```

### Pod Label Selectors
Scripts detect pods via multiple label strategies:
1. `app.kubernetes.io/instance=<release>` (Helm standard)
2. `app=<selector>` (extracted from YAML metadata.labels.app)

Always include `app: <name>` in deployment labels for compatibility.

## Cluster Requirements

### Edge Deployment (Single-Node)
- Default storage: `hostPath` persistence (paths must exist on node)
- Use `hostNetwork: true` for IoT device discovery (mDNS, SSDP)
- Single node means `Recreate` deployment strategy to prevent port conflicts

### Cluster Deployment (Multi-Node)
- Use `persistence.type: pvc` with a StorageClass
- Install Intel GPU Device Plugin for hardware transcoding:
  ```bash
  kubectl apply -k https://github.com/intel/intel-device-plugins-for-kubernetes/deployments/gpu_plugin/overlays/nfd_labeled_nodes
  ```
- Install Metrics Server for resource monitoring:
  ```bash
  kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
  ```

## Release Process

Charts are auto-packaged and published to GitHub Pages via [chart-releaser-action](./.github/workflows/release-charts.yaml) on push to `main` branch (when `charts/**` paths change). Bump `version` in `Chart.yaml` to trigger new release.

**Release workflow:**
1. Edit chart files under `charts/<chart-name>/`
2. Bump `version` in `Chart.yaml` (semver required)
3. Commit and push to `main` branch
4. GitHub Action runs chart-releaser:
   - Packages charts using `helm package`
   - Creates GitHub releases with chart archives
   - Updates `index.yaml` on `gh-pages` branch
5. Charts become available at: `https://billy27607.github.io/my-helm-charts`

**Chart-releaser config:**
- `charts_dir: charts` - location of chart sources
- `skip_existing: true` - won't re-release same version
- Auto-creates `gh-pages` branch on first release
