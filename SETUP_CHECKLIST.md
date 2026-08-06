# Setup Checklist for Lens Deployment

Follow this checklist to verify your Helm chart repository is ready for Lens deployment.

## ✅ GitHub Repository Setup

- [ ] Repository exists: `billy27607/my-helm-charts`
- [ ] GitHub Actions workflow exists: `.github/workflows/release-charts.yaml`
- [ ] Workflow has correct permissions (contents, pages, id-token: write)

## ✅ GitHub Pages Setup

1. Go to: https://github.com/billy27607/my-helm-charts/settings/pages
2. Verify settings:
   - [ ] **Source**: Deploy from a branch
   - [ ] **Branch**: `gh-pages` / (root)
   - [ ] **Status**: "Your site is live at https://billy27607.github.io/my-helm-charts"

If `gh-pages` branch doesn't exist yet:
- [ ] Push any change to `main` branch (in `charts/` directory)
- [ ] Wait for GitHub Action to complete
- [ ] `gh-pages` branch will be auto-created

## ✅ Chart Versioning

All charts should have proper semantic versioning in `Chart.yaml`:

- [ ] auto-mount: 0.1.86 ✓
- [ ] avahi-daemon: 0.1.0 ✓
- [ ] firefox-remote: 0.1.0 ✓
- [ ] hdhomerun-app-proxy: 0.1.0 ✓
- [ ] hdhomerun-tuner-proxy: 0.1.0 ✓
- [ ] homebridge: 0.5.0 ✓
- [ ] iperf3: 0.2.0 ✓
- [ ] mdns-reflector: 0.3.6 ✓
- [ ] octoprint: 0.1.0 ✓
- [ ] prometheus: 0.1.0 ✓
- [ ] rtl-sdr: 0.1.0 ✓
- [ ] scrypted: 0.1.0 ✓
- [ ] website-monitor: 0.1.0 ✓
- [ ] xcarve: 0.2.0 ✓

## ✅ Testing the Repository

### Option 1: Command Line Test

```bash
# Add repository
helm repo add my-charts https://billy27607.github.io/my-helm-charts

# Update repository index
helm repo update

# List available charts
helm search repo my-charts/

# Show all versions
helm search repo my-charts/ --versions

# View chart details
helm show chart my-charts/scrypted
helm show values my-charts/scrypted
```

Expected output:
```
NAME                           	CHART VERSION	APP VERSION	DESCRIPTION
my-charts/auto-mount          	0.1.86       	1.0        	Automatic NFS mount manager
my-charts/homebridge          	0.5.0        	latest     	HomeKit bridge with Mosquitto MQTT
my-charts/scrypted            	0.1.0        	latest     	NVR home video integration
...
```

### Option 2: Check index.yaml Directly

```bash
# View published chart index
curl https://billy27607.github.io/my-helm-charts/index.yaml

# Or in browser
open https://billy27607.github.io/my-helm-charts/index.yaml
```

Should see entries for all your charts with versions and download URLs.

### Option 3: Check GitHub Releases

1. Go to: https://github.com/billy27607/my-helm-charts/releases
2. Verify releases exist for each chart version
3. Each release should have:
   - Tag: `<chart-name>-<version>` (e.g., `scrypted-0.1.0`)
   - Assets: `<chart-name>-<version>.tgz`

## ✅ Lens Configuration

In Lens:

1. **Add Repository**:
   - [ ] Open Lens → Connect to cluster
   - [ ] Navigate to Helm → Charts
   - [ ] Click gear icon ⚙️
   - [ ] Add repository:
     - Name: `my-charts`
     - URL: `https://billy27607.github.io/my-helm-charts`
   - [ ] Click Add

2. **Verify Charts Available**:
   - [ ] Select `my-charts` from repository dropdown
   - [ ] All 14 charts should appear
   - [ ] Click on a chart to see versions and README

3. **Test Deployment**:
   - [ ] Select a simple chart (e.g., `iperf3`)
   - [ ] Click Install
   - [ ] Set release name: `iperf3-test`
   - [ ] Set namespace: `test`
   - [ ] Review values
   - [ ] Click Install
   - [ ] Monitor deployment in Workloads → Pods
   - [ ] Verify pod reaches Running state

## 🔧 Troubleshooting

### Problem: Repository URL returns 404

**Cause**: GitHub Pages not enabled or `gh-pages` branch doesn't exist

**Solution**:
1. Enable GitHub Pages in repo settings
2. Trigger workflow by making a change to any chart
3. Wait 2-5 minutes for GitHub Pages to build

### Problem: Charts don't appear in Lens

**Cause**: Repository not added correctly or Lens cache

**Solution**:
1. Remove and re-add repository in Lens
2. Restart Lens
3. Verify URL is correct: `https://billy27607.github.io/my-helm-charts`

### Problem: GitHub Action fails

**Check**:
1. Go to: https://github.com/billy27607/my-helm-charts/actions
2. Click on failed workflow
3. Review error logs
4. Common issues:
   - Invalid Chart.yaml syntax
   - Missing required fields (name, version)
   - Branch protection rules
   - Insufficient permissions

### Problem: Old version still showing

**Cause**: Chart version wasn't bumped

**Solution**:
1. Edit `charts/<chart-name>/Chart.yaml`
2. Increment version: `0.1.0` → `0.1.1`
3. Commit and push
4. Wait for workflow to complete
5. In Lens: Remove and re-add repo or wait for auto-refresh

## 📋 First-Time Publishing Checklist

If you haven't published charts yet:

1. **Verify all charts are ready**:
   ```bash
   # Validate each chart
   for chart in charts/*/; do
       echo "Validating $chart"
       helm lint "$chart"
   done
   ```

2. **Commit and push**:
   ```bash
   git add README.md LENS_DEPLOYMENT_GUIDE.md SETUP_CHECKLIST.md
   git commit -m "Update documentation for Lens deployment"
   git push origin main
   ```

3. **Wait for GitHub Action**:
   - Go to: https://github.com/billy27607/my-helm-charts/actions
   - Watch "Release Charts" workflow
   - Should complete in 1-3 minutes

4. **Verify GitHub Pages**:
   - Check: https://billy27607.github.io/my-helm-charts
   - Should redirect or show basic page
   - Check: https://billy27607.github.io/my-helm-charts/index.yaml
   - Should show chart index

5. **Test in Lens**:
   - Add repository
   - Deploy a test chart
   - Verify functionality

## 🎯 Next Steps

Once everything is verified:

1. **Document custom values**: Save your production values files
2. **Create deployment runbook**: Document standard procedures
3. **Set up monitoring**: Use Lens to monitor deployments
4. **Plan upgrades**: Test chart updates in dev before production

## 📚 Reference

- [Complete Lens Guide](./LENS_DEPLOYMENT_GUIDE.md)
- [Repository README](./README.md)
- [Architecture Docs](.github/copilot-instructions.md)
- [GitHub Actions Workflow](.github/workflows/release-charts.yaml)
