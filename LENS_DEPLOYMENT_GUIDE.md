# Deploying Charts with Lens

This guide shows how to use Lens to deploy and manage your Helm charts from this repository.

## Initial Setup (One-Time)

### 1. Add the Chart Repository to Lens

1. Open **Lens** and connect to your cluster
2. Click on **Helm** in the left sidebar
3. Click **Charts** tab
4. Click the **⚙️ (gear icon)** in the top-right or **Add Repository** button
5. Fill in the form:
   - **Name**: `my-charts`
   - **URL**: `https://billy27607.github.io/my-helm-charts`
6. Click **Add**

The repository will now appear in your charts list and auto-refresh when you update charts.

### 2. Verify Repository

1. In Lens **Helm** > **Charts**
2. Select `my-charts` from the repository dropdown
3. You should see all available charts:
   - scrypted
   - homebridge
   - iperf3
   - mdns-reflector
   - octoprint
   - prometheus
   - firefox-remote
   - hdhomerun-app-proxy
   - hdhomerun-tuner-proxy
   - website-monitor
   - xcarve
   - auto-mount
   - avahi-daemon
   - rtl-sdr

## Deploying a Chart

### From Lens GUI (Recommended)

1. **Select Chart**:
   - Go to **Helm** > **Charts**
   - Filter by `my-charts` repository
   - Click on the chart you want (e.g., `scrypted`)

2. **Choose Version**:
   - View available versions in the dropdown
   - Select the version to install (usually latest)

3. **Configure Installation**:
   - Click **Install** button
   - Set **Release Name**: e.g., `scrypted-prod`
   - Set **Namespace**: e.g., `ourplan` (or create new)
   - Edit **Values YAML** to customize:
     ```yaml
     hostNetwork: true
     
     devices:
       usb: true  # For Coral TPU
       dri: true  # For Intel QuickSync
     
     persistence:
       enabled: true
       type: hostPath
       hostPath: /mnt/nvr/scrypted
     
     intelGpu:
       enabled: true
     ```

4. **Deploy**:
   - Click **Install** at the bottom
   - Lens will show deployment progress
   - Wait for pod to become **Running**

### Viewing Deployed Charts

1. Go to **Helm** > **Releases**
2. See all installed charts with:
   - Release name
   - Chart name and version
   - Namespace
   - Status (deployed, pending, failed)
   - Age

3. Click on a release to see:
   - Resources (deployments, services, config maps)
   - Values used
   - Revision history
   - Notes

### Monitoring Deployment

1. **View Pods**:
   - Go to **Workloads** > **Pods**
   - Filter by namespace
   - Check pod status (Running, Pending, CrashLoopBackOff)

2. **View Logs**:
   - Click on the pod
   - Select **Logs** tab
   - Use search and filters

3. **View Events**:
   - In pod details, go to **Events** tab
   - Check for errors or warnings

4. **Shell Access**:
   - In pod details, click **Pod Shell** icon
   - Opens terminal inside container

## Upgrading a Chart

### From Lens GUI

1. Go to **Helm** > **Releases**
2. Find your release (e.g., `scrypted-prod`)
3. Click **Upgrade** button
4. Options:
   - **Change version**: Select new chart version
   - **Edit values**: Modify YAML configuration
   - **Reuse values**: Keep existing config
5. Click **Upgrade**

### Common Upgrade Scenarios

#### Update to Latest Chart Version
1. Releases → Select release → Upgrade
2. Choose latest version from dropdown
3. Check "Reuse values" to keep your config
4. Click Upgrade

#### Change Configuration
1. Releases → Select release → Upgrade
2. Keep same version
3. Edit Values YAML (e.g., enable `hostNetwork`)
4. Click Upgrade

#### Force Restart
1. Releases → Select release
2. Click **Rollback** then **Upgrade** with same version
3. Or use kubectl: `kubectl rollout restart deployment/<name> -n <namespace>`

## Uninstalling a Chart

1. Go to **Helm** > **Releases**
2. Find your release
3. Click the **⋮** (three dots) menu
4. Select **Uninstall**
5. Confirm deletion

**Note**: This removes the Helm release and most resources, but may leave PersistentVolumeClaims (PVCs) if configured to retain data.

## Troubleshooting in Lens

### Chart Won't Install

1. **Check Events**:
   - Workloads → Pods → Select pod → Events tab
   - Look for ImagePullBackOff, CrashLoopBackOff

2. **Check Logs**:
   - Find the pod → Logs tab
   - Look for startup errors

3. **Common Issues**:
   - **Image pull errors**: Check image name/tag in values
   - **Port conflicts**: Ensure no other service uses same hostPort
   - **Device access**: Verify `privileged: true` for USB/serial devices
   - **Storage**: Check hostPath exists on node

### Pod is Pending

1. Check pod events for scheduling issues
2. Common causes:
   - Node doesn't have requested resources
   - PVC not bound (storage issue)
   - Node selector doesn't match any node

### Pod is CrashLoopBackOff

1. View pod logs for startup errors
2. Check:
   - Environment variables
   - Volume mounts (paths must exist)
   - Device access (USB/serial permissions)
   - Application configuration

### Viewing Full Values

1. Helm → Releases → Select release
2. Click **Values** tab
3. Shows merged values (chart defaults + your overrides)

## Best Practices

### Release Naming
- Use descriptive names: `scrypted-prod`, `homebridge-main`
- Avoid conflicts with chart names
- Use namespace to isolate environments

### Namespaces
- Create dedicated namespaces: `ourplan`, `homeautomation`, `monitoring`
- Use namespace for logical grouping (all IoT charts in one namespace)

### Version Management
- Pin to specific versions for production: `0.5.0`
- Use latest version for testing
- Review release notes before upgrading

### Values Management
- Keep values in version control (git)
- Use separate values files for different environments
- Document customizations in values.yaml comments

### Backup
- Export installed values: Helm → Releases → Release → Values → Copy
- Store in git or notes before major changes
- Can reinstall with same config if needed

## Workflow: Development to Production

### 1. Local Development
```bash
# Test chart locally
./scripts/k8s-helpers.sh helm-install scrypted test-release --namespace=test

# Iterate and test changes
./scripts/k8s-helpers.sh helm-upgrade scrypted test-release --namespace=test --set key=value

# Verify functionality
./scripts/k8s-helpers.sh helm-logs test-release --namespace=test
```

### 2. Publish Chart
```bash
# Bump version in Chart.yaml
# Commit and push to GitHub
git add charts/scrypted/Chart.yaml
git commit -m "Release scrypted v0.2.0"
git push origin main

# GitHub Actions automatically publishes
```

### 3. Deploy via Lens
1. Open Lens
2. Refresh chart repositories (automatic or manual refresh)
3. Helm → Charts → my-charts → scrypted
4. Install new version with production values
5. Monitor deployment in Workloads view

### 4. Verify and Monitor
- Check pod status in Workloads
- View logs for errors
- Test application functionality
- Monitor resources

## Quick Reference

| Task | Steps |
|------|-------|
| Add repo | Helm → Charts → ⚙️ → Add `https://billy27607.github.io/my-helm-charts` |
| Deploy chart | Helm → Charts → Select chart → Install |
| Upgrade | Helm → Releases → Select → Upgrade |
| View logs | Workloads → Pods → Select pod → Logs |
| Shell access | Workloads → Pods → Select pod → Pod Shell icon |
| Uninstall | Helm → Releases → Select → ⋮ → Uninstall |
| Check events | Workloads → Pods → Select pod → Events |

## Additional Resources

- [Helm Documentation](https://helm.sh/docs/)
- [Lens Documentation](https://docs.k8slens.dev/)
- [Chart Development Guide](./README.md#development)
- [Architecture Overview](.github/copilot-instructions.md)
