# Copilot Instructions for my-helm-charts

## Repository Overview

This is a **home lab Helm charts repository** for deploying smart home and media services on Kubernetes. Charts are hosted on GitHub Pages and designed for single-node edge deployments with hardware device access (USB, GPU, serial).

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

**Common devices in this homelab:**
- **Coral TPU** (USB): `devices.usb: true` for ML object detection in Scrypted
- **Intel QuickSync** (/dev/dri): `devices.dri: true` + `intelGpu.enabled: true` for hardware video transcoding
- **Z-Wave USB** (/dev/ttyACM0): `devices.serial` for Z-Wave JS integration
- **Zigbee USB** (/dev/ttyACM1): Additional serial device for Zigbee coordinators

### Multi-Component Charts
The `frontst` chart bundles 4 services (Homebridge, Mosquitto, Scrypted, Z-Wave JS) for complex home automation stacks. Each component has:
- Separate `deployment-<name>.yaml` and `service-<name>.yaml` templates
- Conditional enablement via `.<component>.enabled` in values
- Shared helpers in `_helpers.tpl` with component-specific label functions

## Development Workflows

### Local Testing with k8s-helpers.sh
**Never kubectl commands directly in tasks** - use the k8s-helpers.sh script:

```bash
# Helm workflows (preferred)
./scripts/k8s-helpers.sh helm-install scrypted my-release --set hostNetwork=false
./scripts/k8s-helpers.sh helm-upgrade scrypted my-release --values custom.yaml
./scripts/k8s-helpers.sh helm-status my-release
./scripts/k8s-helpers.sh helm-logs my-release     # Auto-detects pod labels
./scripts/k8s-helpers.sh helm-restart my-release  # Rollout restart
./scripts/k8s-helpers.sh helm-uninstall my-release

# Direct YAML workflows (legacy)
./scripts/k8s-helpers.sh status deployment.yaml
./scripts/k8s-helpers.sh logs deployment.yaml     # Extracts app selector
./scripts/k8s-helpers.sh events deployment.yaml
./scripts/k8s-helpers.sh resources deployment.yaml
```

### VS Code Tasks
Run via Command Palette → "Run Task":
- **helm: Install/Upgrade/Status/Logs/Restart/Uninstall** - Helm lifecycle operations
- **k8s: Deploy/Status/Logs/Events/Teardown** - Direct kubectl operations

Tasks source chart names from `${workspaceFolder}/charts/` automatically.

## Code Conventions

### Template Helpers Pattern
All charts follow standard Helm helper structure in `_helpers.tpl`:
```go
{{- define "<chart>.name" -}}...{{- end }}
{{- define "<chart>.fullname" -}}...{{- end }}
{{- define "<chart>.labels" -}}...{{- end }}
{{- define "<chart>.selectorLabels" -}}...{{- end }}
```

For multi-component charts, add component-specific variants:
```go
{{- define "frontst.scrypted.labels" -}}
{{- define "frontst.mosquitto.selectorLabels" -}}
```

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

### Device Access Failures
**Required**: `privileged: true` for serial/USB devices  
**Common issue**: Device paths change on reboot (e.g., `/dev/ttyACM0` → `/dev/ttyACM1`)  
**FCluster Requirements

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
./scripts/k8s-helpers.sh helm-install my-service test-release
```

### Migrating from Docker Compose
1. Copy service config from `scrypted-compose.yaml` or similar
2. Create chart structure matching existing single-service charts (like scrypted) or multi-component charts (like frontst)
3. Key translations:
   - `network_mode: host` → `hostNetwork: true`
   - `volumes` → `persistence.hostPath` or `volumeMounts`
   - `devices` → `devices.serial/usb/dri` + `privileged: true`
   - `environment` → `env.extra` array
   - `ports` → `containerPort` (hostNetwork exposes all ports)

### Chart Testing Workflow
```bash
# Install and watch logs
./scripts/k8s-helpers.sh helm-install my-chart test-release
./scripts/k8s-helpers.sh helm-logs test-release

# Iterate on templates
./scripts/k8s-helpers.sh helm-upgrade my-chart test-release --set key=value

# Check status and events
./scripts/k8s-helpers.sh helm-status test-release
kubectl get events --sort-by='.lastTimestamp' | tail -20
```

## ix**: Use udev rules or `/dev/serial/by-id/*` paths in `devices.serial`

### Pod Label Selectors
Scripts detect pods via multiple label strategies:
1. `app.kubernetes.io/instance=<release>` (Helm standard)
2. `app=<selector>` (extracted from YAML metadata.labels.app)

Always include `app: <name>` in deployment labels for compatibility.

## Release Process

Charts are auto-packaged and published to GitHub Pages via chart-releaser action on push to `main`. Bump `version` in `Chart.yaml` to trigger new release.
