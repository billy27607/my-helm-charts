# Auto-Mount Chart

Simple automatic mounting and SMB sharing for hot-swap drives and optical discs.

## Features

- **Auto-Mount Hot-Swap Drives**: Automatically detects and mounts drives inserted into hot-swap bays
- **Auto-Mount Optical Discs**: Automatically mounts CD/DVD/Blu-ray discs
- **SMB Sharing**: Both mount points are shared via Samba (SMB/CIFS)
- **Simple Web UI**: Minimal interface to unmount drives and eject discs

## Prerequisites

1. Label your node:
```bash
kubectl label node <node-name> automount=true
```

2. The host paths must be available:
- `/hotswap` for hot-swap drives
- `/optical-mount` for optical discs

## Installation

```bash
helm install automount ./charts/auto-mount \
  --set samba.username=media \
  --set samba.password=YourSecurePassword
```

## Access

- **Web UI**: https://bhost.baezw.com/automount (if ingress enabled)
- **SMB Share (Hot-Swap)**: `\\<node-ip>\hotswap`
  - Username: `media` (or configured value)
  - Password: Set in values.yaml
- **SMB Share (Optical)**: `\\<node-ip>\optical` (read-only, guest access)

## Configuration

Key values in `values.yaml`:

```yaml
# SMB credentials
samba:
  username: media
  password: ChangeMeNow!

# Mount paths
hotswapPath: /hotswap
opticalPath: /optical-mount

# Web UI port
webui:
  port: 8888
```

## How It Works

1. Container runs with privileged mode to access `/dev` devices
2. Monitors for block devices (`/dev/sd*` for hot-swap, `/dev/sr0` for optical)
3. Auto-mounts devices when detected
4. Samba shares the mount points
5. Web UI provides unmount/eject controls

## Notes

- Requires `hostNetwork: true` for SMB discovery
- Requires `privileged: true` for mount operations
- Uses `Recreate` deployment strategy for single-node setups
