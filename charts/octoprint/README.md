# OctoPrint Helm Chart

OctoPrint is the snappy web interface for your 3D printer that allows you to control and monitor all aspects of your printer and print jobs, right from your browser.

This chart includes:
- **OctoPrint** - Main 3D printer control interface
- **MJPG-Streamer** - Webcam streaming for real-time print monitoring

## Features

- 🖨️ 3D printer control and monitoring
- 📹 Built-in webcam streaming via MJPG-Streamer
- 🔌 Configurable USB serial device access
- 💾 PersistentVolumeClaim storage (no manual host setup required)
- 🌐 Ingress support for external access
- 🎛️ Resource limits and requests
- 🔒 Security context for device access

## Prerequisites
Video device for webcam (e.g., `/dev/video0`)
- StorageClass configured for persistent volumes (or use default
- Kubernetes 1.19+
- Helm 3.0+
- USB serial device for 3D printer (e.g., `/dev/ttyUSB0` or `/dev/ttyACM0`)
- Optional: Webcam device for monitoring (e.g., `/dev/video0`)

## Installation

### Quick Start

```bash
helm install octoprint ./charts/octoprint
```

### With Custom Values

```bash
helm insoctoprint.serialPort=/dev/ttyACM0 \
  --set octoprint.persistence.size=20Gi \
  --set mjpgStreamer.device=/dev/video1
```

### Using k8s-helpers.sh (Recommended)

```bash
scripts/k8s-helpers.sh helm-install octoprint my-octoprint \
  --namespace=default \
  --set octoprint.serialPort=/dev/ttyACM0
scripts/k8s-helpers.sh helm-install octoprint my-octoprint --namespace=default
```

## Configuration

### Key Configuration Options
octoprint.enabled` | Enable OctoPrint deployment | `true` |
| `octoprint.image.repository` | OctoPrint image repository | `octoprint/octoprint` |
| `octoprint.image.tag` | OctoPrint image tag | `1.10.2` |
| `octoprint.serialPort` | Serial device path for printer | `/dev/ttyUSB0` |
| `octoprint.hostNetwork` | Use host network | `false` |
| `octoprint.service.type` | Kubernetes service type | `ClusterIP` |
| `octoprint.service.port` | Service port | `80` |
| `octoprint.securityContext.privileged` | Required for device access | `true` |
| `octoprint.persistence.enabled` | Enable persistent storage | `true` |
| `octoprint.persistence.size` | Storage size | `10Gi` |
| `octoprint.persistence.storageClass` | StorageClass name (empty = default) | `""` |
| `mjpgStreamer.enabled` | Enable webcam streaming | `true` |
| `mjpgStreamer.device` | Video device path | `/dev/video0` |
| `mjpgStreamer.resolution` | Camera resolution | `640x480` |
| `mSerial Port Configuration

Specify your printer's serial port in values.yaml:

```yaml
octoprint:
  serialPort: /dev/ttyUSB0  # or /dev/ttyACM0 for Arduino-based boards
```

**Finding your serial port:**
```bash
# List available serial devices
ls -l /dev/ttyUSB* /dev/ttyACM*

# Use stable by-id paths (recommended)
ls -l /dev/serial/by-id/
```

**Using stable device paths:**
```yaml
octoprint:
octoprint:
  persistence:
    enabled: true
    size: 10Gi
    storageClass: ""  # Uses default StorageClass
```

**Custom StorageClass:**
```yaml
octoprint:
  persistence:
    enabled: true
    size: 20Gi
    storageClass: "fast-ssd"
```

### Ingress Configuration

```yaml
octoprint:
  ingress:
    enabled: true
    className: nginx
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt-prod
      nginx.ingress.kubernetes.io/proxy-body-size: "0"  # Allow large gcode uploads
    hosts:
      - host: octoprint.example.com
        paths:
          - path: /
            pathType: Prefix
    tls:
      - secretName: octoprint-tls
        hosts:
  #### Cluster Deployment

```yaml
persistence:
  enabled: true
  type: pvc
  size: 10Gi
  storageClass: "your-storage-class"
```

### Ingress Configuration

```yaml
ingress:
  enabled: true
  className: nginx
  annotations:my-octoprint 8080:80
```

Then open http://localhost:8080 in your browser.

### Access Webcam Stream

Forward the MJPG-Streamer port:

```bash
kubectl port-forward svc/my-octoprint-mjpg-streamer 8081:8080
```

Then open http://localhost:8081/?action=stream in your browser.

### Configure Webcam in OctoPrint

In OctoPrint settings, confimy-octoprint -- ls -l /dev/ttyUSB0
```

### View Logs

```bash
# OctoPrint logs
kubectl logs -f deployment/my-octoprint

# MJPG-Streamer logs
kubectl logs -f deployment/my-octoprint-mjpg-streamer

# Using k8s-helpers.sh
scripts/k8s-helpers.sh helm-logs my-
```

## Usage
serial port configuration**:
   ```bash
   # Check your values.yaml
   helm get values my-octoprint
   ```

2. **Check device exists on node**:
   ```bash
   ls -l /dev/ttyUSB* /dev/ttyACM*
   ```

3. **Check device permissions**:
   ```bash
   kubectl exec -it deployment/my-octoprint -- ls -l /dev/ttyUSB0
   ```

4. **Use stable device paths**:
   ```yaml
   octoprint:
     serialPort:he serial device is accessible:

```bash
kubectl exec -it deployment/octoprint -- ls -l /dev/ttyUSB0
```

### View Logs

```bash
# Using kubectl
kubectl logs -f deployment/octoprint

# Using k8s-helpers.sh
scripts/k8s-helpers.sh helm-logs octoprint
```

## Troubleshooting

### Printer Not Detected
configure:
```yaml
octoprint:
  serialPort: /dev/printer3d
```

### Webcam Not Working

1. **Verify MJPG-Streamer is enabled**:
   ```yaml
   mjpgStreamer:
     enabled: true
   ```

2. **Check video device**:
   ```bash
   kubectl exec -it deployment/my-octoprint-mjpg-streamer -- ls -l /dev/video0
   ```

3. **Adjoctoprint.securityContext.privileged: true` is set. Device access requires privileged containers.

### Storage Issues

If PVC is pending:
```bash
# Check PVC smy-octoprint ./charts/octoprint

# Using k8s-helpers.sh (auto-detects conflicts)
scripts/k8s-helpers.sh helm-upgrade octoprint my-octoprint --namespace=default
```

## Uninstalling

```bash
# Using Helm (PVC will persist)
helm uninstall my-octoprint

# Using k8s-helpers.sh
scripts/k8s-helpers.sh helm-uninstall my-octoprint

# Delete PVC if needed
kubectl delete pvc my- laggy
   ```

4. **Test the stream directly**:
   ```bash
   kubectl port-forward svc/my-octoprint-mjpg-streamer 8081:8080
   # Open http://localhost:8081/?action=streamy-id/
octoprint:
  nodeSelector:
    kubernetes.io/hostname: printer-node

# Or use affinity for more complex rules
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: hardware.device/3dprinter
          operator: Exists
```

### Resource Limits

Adjust based on your print complexity and webcam usage:

```yaml
octoprint:
  resources:
    limits:
      cpu: 2000m
      memory: 2Gi
    requests:
      cpu: 500m
      memory: 512Mi

mjpgStreamer:
  resources:
    limits:
      cpu: 500m
      memory: 256Mi
```

### Disable Webcam

If you don't need webcam streaming:

```yaml
mjpgStreamer:
  enabled: falseinter3d` in your values.

### Webcam Not Working

1. Verify video device is mounted:
   ```bash
   kubectl exec -it deployment/octoprint -- ls -l /dev/video0
   ```

2. Enable MJPG-Streamer in environment:
   ```yaml
   env:
     extra:
       - name: ENABLE_MJPG_STREAMER
         value: "true"
   ```

### Permission Denied Errors

Ensure `securityContext.privileged: true` is set. Device access requires privileged containers.

## Upgrading

```bash
# Using Helm
helm upgrade octoprint ./charts/octoprint

# Using k8s-helpers.sh (auto-detects conflicts)
scripts/k8s-helpers.sh helm-upgrade octoprint octoprint --namespace=default
```

## Uninstalling

```bash
# Using Helm
helm uninstall octoprint

# Using k8s-helpers.sh
scripts/k8s-helpers.sh helm-uninstall octoprint
```

## Advanced Configuration

### Node Affinity

Deploy to a specific node with the 3D printer attached:

```yaml
nodeSelector:
  kubernetes.io/hostname: printer-node

# Or use affinity for more complex rules
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: hardware.device/3dprinter
          operator: Exists
```

### Resource Limits

Adjust based on your print complexity and webcam usage:

```yaml
resources:
  limits:
    cpu: 2000m
    memory: 2Gi
  requests:
    cpu: 500m
    memory: 512Mi
```

## References

- [OctoPrint Documentation](https://docs.octoprint.org)
- [OctoPrint Docker Image](https://hub.docker.com/r/octoprint/octoprint)
- [OctoPrint GitHub](https://github.com/OctoPrint/OctoPrint)
