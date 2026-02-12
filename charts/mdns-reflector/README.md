# mDNS Reflector

Selective mDNS/Bonjour reflector for multi-site networks with service filtering and **unicast forwarding for cross-VPN mDNS**. Perfect for reflecting services like NAS, printers, and Time Machine across VPN-connected sites while blocking conflicting announcements.

## Features

- **Selective Service Reflection**: Only reflect specific mDNS service types (NAS, printers, etc.)
- **Service Blocking**: Explicitly block problematic services (UniFi devices, Chromecasts, etc.)
- **Unicast Forwarding**: Forward mDNS across VPN/WAN links where multicast doesn't work
- **Multi-Site Support**: Works across VPN connections (tested with UniFi Site Magic VPN)
- **Auto-Detection**: Automatically detects network interfaces or manually specify them
- **Real-time Filtering**: Python-based service filter monitors and logs reflected services

## Use Case

Ideal for environments with:
- Multiple sites connected via VPN (e.g., UniFi Site Magic VPN)
- Centralized resources (NAS, printers) at main site
- Need to access resources from remote site via Bonjour/mDNS
- Conflicting mDNS announcements (UniFi devices, cameras, etc.)

## How It Works

### Local Reflection (Single Site)
Uses Avahi's built-in reflector to bounce mDNS between network interfaces on the same subnet.

### Cross-Site Forwarding (Multi-Site)
Since mDNS uses link-local multicast that doesn't traverse VPNs, the unicast forwarder:
1. Listens for mDNS multicast on the local network
2. Forwards matching announcements as **unicast packets** to peer reflectors
3. Peer receives unicast and re-announces as mDNS on their local network

## Quick Start

### Cross-Site Deployment (Recommended)

### Cross-Site Deployment (Recommended)

For VPN-connected sites where you want mDNS to work across the WAN link:

**Step 1: Get the pod IP from the remote site**
```bash
# On remote site cluster (192.168.101.0/24)
kubectl config use-context remote-site
helm install mdns-remote ./charts/mdns-reflector \
  --namespace networking \
  --create-namespace \
  --set unicast.enabled=true

# Get the node IP where the pod is running
kubectl get pods -n networking -l app.kubernetes.io/name=mdns-reflector -o wide
# Note the NODE column IP (e.g., 192.168.101.10)
```

**Step 2: Deploy on main site with peer configuration**
Create `values-main.yaml`:
```yaml
unicast:
  enabled: true
  port: 5354
  peers:
    - "192.168.101.10:5354"  # Remote site node IP

allowedServices:
  - _smb._tcp
  - _printer._tcp
  - _ipp._tcp
  - _adisk._tcp
```

Deploy:
```bash
kubectl config use-context main-site
helm install mdns-main ./charts/mdns-reflector \
  --namespace networking \
  --create-namespace \
  --values values-main.yaml
```

**Step 3: Configure remote site with main site peer**
```bash
# Get main site node IP
kubectl config use-context main-site
kubectl get pods -n networking -l app.kubernetes.io/name=mdns-reflector -o wide
# Note the NODE IP (e.g., 192.168.100.25)

# Update remote site with peer
kubectl config use-context remote-site
helm upgrade mdns-remote ./charts/mdns-reflector \
  --namespace networking \
  --set unicast.enabled=true \
  --set unicast.peers={192.168.100.25:5354}
```

**Step 4: Verify cross-site forwarding**
```bash
# Check logs on main site
kubectl logs -n networking -l app.kubernetes.io/name=mdns-reflector | grep UNICAST

# You should see:
# [UNICAST-TX] Forwarded 245 bytes to 1 peer(s)
# [UNICAST-RX] Received 245 bytes from 192.168.101.10, re-announced as mDNS
```

### Basic Installation (Main Site)

Deploy on the main site (192.168.100.0/24) to reflect services locally only:

```bash
helm install mdns-reflector ./charts/mdns-reflector \
  --namespace networking \
  --create-namespace
```

### Basic Installation (Remote Site)

Deploy on the remote site (192.168.101.0/24) to receive reflected services:

```bash
helm install mdns-reflector ./charts/mdns-reflector \
  --namespace networking \
  --create-namespace
```

## Configuration

### Service Filtering

By default, the chart reflects common services and blocks problematic ones. Customize in `values.yaml`:

```yaml
# Only reflect these service types
allowedServices:
  - _smb._tcp              # SMB/CIFS file shares
  - _printer._tcp          # Printers
  - _ipp._tcp              # Internet Printing Protocol
  - _adisk._tcp            # Time Machine

# Block these services (even if in allowedServices)
blockedServices:
  - _ubnt._tcp             # UniFi devices
  - _ubnt-discover._tcp    # UniFi discovery
  - _googlecast._tcp       # Chromecast
```

### Network Interfaces

Auto-detect interfaces (recommended):
```yaml
reflector:
  autoDetect: true
```

Or manually specify:
```yaml
reflector:
  autoDetect: false
  interfaces:
    - eth0      # Main network interface
    - wg0       # VPN interface (UniFi Site Magic)
```

### Custom Service List

Add custom services to reflect:
```yaml
allowedServices:
  - _smb._tcp
  - _airplay._tcp
  - _my-custom-service._tcp
```

## Deployment Scenarios

### Scenario 1: Single Reflector at Main Site

Deploy only at main site to reflect services outbound to remote site:

```bash
# Main site (192.168.100.0/24)
helm install mdns-main ./charts/mdns-reflector \
  --namespace networking \
  --create-namespace
```

### Scenario 2: Reflectors at Both Sites

Deploy at both sites for bidirectional reflection:

```bash
# Main site
helm install mdns-main ./charts/mdns-reflector --namespace networking --create-namespace

# Remote site
helm install mdns-remote ./charts/mdns-reflector --namespace networking --create-namespace
```

### Scenario 3: Site-Specific Filtering

Use different service filters per site:

**Main site (reflect NAS and printer):**
```yaml
# values-main.yaml
allowedServices:
  - _smb._tcp
  - _afpovertcp._tcp
  - _printer._tcp
  - _ipp._tcp
  - _adisk._tcp
```

```bash
helm install mdns-main ./charts/mdns-reflector \
  --namespace networking \
  --values values-main.yaml
```

**Remote site (reflect only printer):**
```yaml
# values-remote.yaml
allowedServices:
  - _printer._tcp
  - _ipp._tcp
```

```bash
helm install mdns-remote ./charts/mdns-reflector \
  --namespace networking \
  --values values-remote.yaml
```

## Common Service Types

### File Sharing
- `_smb._tcp` - SMB/CIFS (Windows/Samba)
- `_afpovertcp._tcp` - AFP (Apple File Protocol)
- `_nfs._tcp` - NFS
- `_adisk._tcp` - Apple Disk (Time Machine)

### Printers
- `_printer._tcp` - Generic printers
- `_ipp._tcp` - Internet Printing Protocol
- `_ipps._tcp` - IPP over SSL
- `_pdl-datastream._tcp` - Print data stream
- `_scanner._tcp` - Network scanners

### Media
- `_airplay._tcp` - AirPlay
- `_raop._tcp` - Remote Audio Output
- `_daap._tcp` - iTunes sharing

## Troubleshooting

### Check if reflector is running:
```bash
kubectl logs -n networking -l app.kubernetes.io/name=mdns-reflector
```

### Test mDNS resolution (from client):
```bash
# macOS
dns-sd -B _smb._tcp local.

# Linux
avahi-browse -a -t -r
```

### View filtered services:
```bash
kubectl logs -n networking -l app.kubernetes.io/name=mdns-reflector | grep FILTERED
```

### Common Issues

**Services not appearing on remote site:**
- Ensure both sites have the reflector deployed
- Check that VPN is connected
- Verify service is in `allowedServices` list
- Check firewall allows UDP 5353 (mDNS)

**UniFi devices still appearing:**
- Add `_ubnt._tcp` and `_ubnt-discover._tcp` to `blockedServices`
- Restart the reflector pod

**Duplicate services:**
- Deploy only one reflector per network segment
- Use `denyInterfaces: "lo"` to prevent loopback reflection

## Requirements

- Kubernetes cluster with `hostNetwork` support
- NET_ADMIN and NET_RAW capabilities
- VPN or routed connection between sites
- UDP 5353 allowed through firewall

## Architecture

The chart uses:
- **Avahi daemon**: mDNS responder and reflector
- **Python service filter**: Monitors and filters mDNS services
- **hostNetwork mode**: Required for mDNS to work across subnets
- **ConfigMap**: Stores Avahi configuration and filter script

## Notes

- Uses `hostNetwork: true` - required for cross-subnet mDNS
- Single replica (Recreate strategy) to prevent conflicts
- Runs in privileged mode with NET_ADMIN capability
- Auto-detects network interfaces by default
