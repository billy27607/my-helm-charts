# Quick Deploy Guide

## Prerequisites

1. **Deploy avahi-daemon DaemonSet** (once per cluster):
```bash
helm install avahi-daemon ./charts/avahi-daemon --namespace kube-system --create-namespace
```

2. **Update Scrypted** (if running):
```bash
helm upgrade scrypted ./charts/scrypted --namespace scrypted --set env.avahiEnabled=false --reuse-values
```

## Deploy mdns-reflector

### Using Helm CLI

**Main Site (bsmart - 192.168.100.0/24):**
```bash
helm upgrade --install mdns-reflector ./charts/mdns-reflector \
  --namespace default \
  --set unicast.peers[0]=192.168.101.25:5354
```

**Remote Site (fsmart - 192.168.101.0/24):**
```bash
helm upgrade --install mdns-reflector ./charts/mdns-reflector \
  --namespace default \
  --set unicast.peers[0]=192.168.100.25:5354
```

### Using VS Code Tasks

**Main Site (bsmart):**
- Task: `helm: Upgrade`
- Chart: `mdns-reflector`
- Release: `mdns-reflector`
- Namespace: `default`
- Extra Args: `--set unicast.peers[0]=192.168.101.25:5354`

**Remote Site (fsmart):**
- Task: `helm: Upgrade`
- Chart: `mdns-reflector`
- Release: `mdns-reflector`
- Namespace: `default`
- Extra Args: `--set unicast.peers[0]=192.168.100.25:5354`

## Verify

```bash
# Check logs
kubectl logs -l app.kubernetes.io/name=mdns-reflector --tail=50

# Should see:
# [UNICAST] Joining multicast group on interface enp0s25 (192.168.100.x)
# [UNICAST-TX] Forwarded _ssh._tcp (bhost.local) to peer
```

## What Changed

**v0.3.5 - Smart DNS Filtering:**
- Proper DNS packet parsing with name compression support
- Forwards hostname lookups (A/AAAA records) for discovered services
- Fixes missing SSH and other service announcements

**v0.3.4 - Raw Socket Forwarding:**
- Raw socket packet capture for all mDNS traffic
- Hostname resolution forwarding (.local domains)

**v0.2.1 - Simplified Deployment:**
- `reflector.enableAvahi: false` - Uses host Avahi (avahi-daemon DaemonSet)
- `unicast.enabled: true` - Cross-site forwarding enabled by default
- `reflector.autoDetect: true` - Auto-detects physical interfaces

**You only need to specify:**
- `unicast.peers[0]` - IP:port of remote reflector node

