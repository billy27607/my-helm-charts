# OctoPrint Helm Chart

OctoPrint is the snappy web interface for your 3D printer that allows you to control and monitor all aspects of your printer and print jobs, right from your browser.

This chart includes:
- **OctoPrint** - Main 3D printer control interface with built-in webcam streaming
- **go2rtc** (optional) - Advanced WebRTC/HLS webcam streaming as an alternative to the built-in streamer

## Features

- 🖨️ 3D printer control and monitoring
- 📹 Built-in webcam streaming via OctoPrint's MJPEG streamer
- 🔌 Configurable USB serial device access for printer
- 📷 Configurable video device access for webcam
- 💾 PersistentVolumeClaim storage (no manual host setup required)
- 🌐 Ingress support for external access
- 🎛️ Resource limits and requests
- 🔒 Security context for device access

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- USB serial device for 3D printer (e.g., `/dev/ttyUSB0` or `/dev/ttyACM0`)
- Optional: Video device for webcam (e.g., `/dev/video0`)
- StorageClass configured for persistent volumes (or use default)

## Installation

### Quick Start

```bash
helm install octoprint ./charts/octoprint
```

### With Custom Values

```bash
helm install octoprint ./charts/octoprint \
  --set octoprint.serialPort=/dev/ttyACM0 \
  --set octoprint.persistence.size=20Gi \
  --set octoprint.webcam.device=/dev/video1
```

### Using k8s-helpers.sh (Recommended)

```bash
scripts/k8s-helpers.sh helm-install octoprint my-octoprint \
  --namespace=default \
  --set octoprint.serialPort=/dev/ttyACM0
```

## Configuration

### Key Configuration Options

| Parameter | Description | Default |
|-----------|-------------|---------|
| `octoprint.enabled` | Enable OctoPrint deployment | `true` |
| `octoprint.image.repository` | OctoPrint image repository | `octoprint/octoprint` |
| `octoprint.image.tag` | OctoPrint image tag | `1.11.6` |
| `octoprint.serialPort` | Serial device path for printer | `/dev/ttyACM0` |
| `octoprint.webcam.enabled` | Enable built-in webcam streaming | `true` |
| `octoprint.webcam.device` | Video device path | `/dev/video0` |
| `octoprint.webcam.resolution` | Camera resolution | `640x480` |
| `octoprint.webcam.fps` | Camera frame rate | `15` |
| `octoprint.hostNetwork` | Use host network | `true` |
| `octoprint.service.type` | Kubernetes service type | `ClusterIP` |
| `octoprint.service.port` | Service port | `80` |
| `octoprint.securityContext.privileged` | Required for device access | `true` |
| `octoprint.persistence.enabled` | Enable persistent storage | `true` |
| `octoprint.persistence.size` | Storage size | `10Gi` |
| `octoprint.persistence.storageClass` | StorageClass name (empty = default) | `""` |
| `mjpgStreamer.enabled` | Enable go2rtc alternative streamer | `false` |

### Serial Port Configuration

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
  serialPort: /dev/serial/by-id/usb-Arduino_Mega_2560-if00
  webcam:
    device: /dev/v4l/by-id/usb-HD_Camera_HD_Camera-video-index0
```

### Webcam Configuration

The built-in OctoPrint webcam streamer is enabled by default:

```yaml
octoprint:
  webcam:
    enabled: true
    device: /dev/video0
    resolution: "640x480"
    fps: 15
```

The webcam stream will be available at `http://<octoprint-url>:8080/?action=stream` (default MJPEG streamer port).

**Alternative: go2rtc Streamer**

For advanced streaming features (WebRTC, HLS), you can enable the go2rtc component:

```yaml
mjpgStreamer:
  enabled: true
  device: /dev/video0
  resolution: "640x480"
  fps: 15
  
octoprint:
  webcam:
    enabled: false  # Disable built-in streamer
```

### Persistent Storage

```yaml
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
  annotations:Then open http://localhost:8080 in your browser.

### Access Webcam Stream

The built-in webcam stream is accessible through OctoPrint's interface at the Control tab, or directly at:

```bash
kubectl port-forward svc/my-octoprint 8080:80
```

Then open http://localhost:8080/webcam/?action=stream in your browser.

**For go2rtc (if enabled):**
```bash
kubectl port-forward svc/my-octoprint-mjpg-streamer 1984:1984
```

Then open http://localhost:1984 in your browser.

### Configure Webcam in OctoPrint

The webcam should be auto-configured. If needed, you can adjust settings in OctoPrint Settings → Webcam & Timelapse:

- **Stream URL**: `/webcam/?action=stream`
- **Snapshot URL**: `/webcam/?action=snapshot`

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

1. **Verify webcam is enabled**:
   ```yaml
   octoprint:
     webcam:
       enabled: true
   ```

2. **Check video device exists**:
   ```bash
   kubectl exec -it deployment/my-octoprint -- ls -l /dev/video0
   ```

3. **Check MJPEG streamer is running**:
   ```bash
   kubectl exec -it deployment/my-octoprint -- ps aux | grep mjpg
   ```

4. **Verify device permissions**: Ensure `octoprint.securityContext.privileged: true` is set. Device access requires privileged containers.

5. **Test the stream**: Access the webcam at `http://<octoprint-url>/webcam/?action=stream`

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
```

### Disable Webcam

If you don't need webcam streaming:

```yaml
octoprint:
  webcam:
    enabled: false
```

### Use go2rtc for Advanced Streaming

For WebRTC, HLS, or other advanced streaming features:

```yaml
octoprint:
  webcam:
    enabled: false  # Disable built-in streamer
    
mjpgStreamer:
  enabled: true  # Enable go2rtc
  device: /dev/video0
  resolution: "640x480"
  fps: 15
  resources:
    limits:
      cpu: 500m
      memory: 256Mi
```

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

## References

- [OctoPrint Documentation](https://docs.octoprint.org)
- [OctoPrint Docker Image](https://hub.docker.com/r/octoprint/octoprint)
- [OctoPrint GitHub](https://github.com/OctoPrint/OctoPrint)
