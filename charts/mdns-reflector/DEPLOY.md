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

### Using VS Code Tasks

**Main Site:**
- Task: `helm: Install` or `helm: Upgrade`
- Chart: `mdns-reflector`
- Release: `mdns-main`
- Namespace: `networking`
- Extra Args: `--set unicast.peers[0]=192.168.101.25:5354`

**Remote Site:**
- Task: `helm: Install` or `helm: Upgrade`
- Chart: `mdns-reflector`
- Release: `mdns-remote`
- Namespace: `networking`
- Extra Args: `--set unicast.peers[0]=192.168.100.25:5354`

### Using Helm CLI

**Main Site (192.168.100.0/24):**
```bash
helm install mdns-main ./charts/mdns-reflector \
  --namespace networking \
  --create-namespace \
  --set unicast.peers[0]=192.168.101.25:5354
```

**Remote Site (192.168.101.0/24):**
```bash
helm install mdns-remote ./charts/mdns-reflector \
  --namespace networking \
  --create-namespace \
  --set unicast.peers[0]=192.168.100.25:5354
```

## Verify

```bash
# Check logs on main site
kubectl logs -n networking -l app.kubernetes.io/instance=mdns-main --tail=50

# Should see:
# [UNICAST] Joining multicast group on interface enp0s25 (192.168.100.x)
# [UNICAST-TX] Forwarded XXX bytes to 1 peer(s)
```

## What Changed (v0.2.1)

**New Defaults:**
- `reflector.enableAvahi: false` - Uses host Avahi (avahi-daemon DaemonSet)
- `unicast.enabled: true` - Cross-site forwarding enabled by default
- `reflector.autoDetect: true` - Auto-detects physical interfaces (excludes k8s internal)

**You only specify:**
- `unicast.peers[0]` - IP:port of remote reflector

**Before (v0.2.0):**
```bash
--set reflector.enableAvahi=false \
--set reflector.autoDetect=false \
--set reflector.interfaces[0]=enp0s25 \
--set unicast.enabled=true \
--set unicast.peers[0]=192.168.101.25:5354
```

**Now (v0.2.1):**
```bash
--set unicast.peers[0]=192.168.101.25:5354
```

That's it! 🎉
