# Avahi Daemon

Installs and manages Avahi daemon on Kubernetes nodes for mDNS/Bonjour service discovery.

## Overview

This DaemonSet ensures every node in your cluster runs the Avahi daemon on the host system. This allows:
- **Scrypted** to discover smart home devices via mDNS
- **mdns-reflector** to forward mDNS traffic across sites
- Any other pods using `hostNetwork: true` to use mDNS

## Features

- Automatically installs Avahi on all nodes
- Configures Avahi with reflection between network interfaces
- Monitors and restarts Avahi if it fails
- Clean integration with systemd

## Installation

```bash
helm install avahi-daemon ./charts/avahi-daemon \
  --namespace kube-system \
  --create-namespace
```

## Configuration

### Avahi Settings

```yaml
avahi:
  domainName: local
  useIPv6: false
  enableReflector: true           # Reflect mDNS between interfaces
  denyInterfaces: "lo,docker0"    # Don't listen on these interfaces
```

### Resource Limits

```yaml
resources:
  limits:
    memory: 64Mi
  requests:
    cpu: 10m
    memory: 32Mi
```

## Usage with Other Charts

### Scrypted

Disable Avahi in Scrypted since it's now running on the host:

```yaml
env:
  avahiEnabled: false
```

### mdns-reflector

Disable Avahi in mdns-reflector to avoid conflicts:

```yaml
reflector:
  enableAvahi: false
unicast:
  enabled: true
  peers:
    - "192.168.101.25:5354"
```

## Verification

Check Avahi is running on the node:

```bash
# List DaemonSet pods
kubectl get pods -n kube-system -l app.kubernetes.io/name=avahi-daemon

# Check logs
kubectl logs -n kube-system -l app.kubernetes.io/name=avahi-daemon --tail=20

# SSH to node and verify
ssh your-node
systemctl status avahi-daemon
avahi-browse -a -t
```

## Uninstallation

```bash
helm uninstall avahi-daemon --namespace kube-system
```

**Note**: Avahi will remain installed on the host but won't be managed by Kubernetes after uninstall. To completely remove:

```bash
# On each node
ssh your-node
sudo systemctl stop avahi-daemon
sudo systemctl disable avahi-daemon
sudo apt-get remove avahi-daemon
```

## Requirements

- Kubernetes nodes must support systemd
- Debian/Ubuntu-based nodes (apt package manager)
- Privileged containers enabled

## Troubleshooting

### Avahi not starting

Check logs:
```bash
kubectl logs -n kube-system -l app.kubernetes.io/name=avahi-daemon
```

SSH to node and check:
```bash
systemctl status avahi-daemon
journalctl -u avahi-daemon -n 50
```

### Services not discovered

Verify Avahi is listening on the correct interface:
```bash
# On the node
ip maddr show | grep 224.0.0.251
avahi-browse -a -t
```
