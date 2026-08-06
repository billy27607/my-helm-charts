# My Helm Charts

A Helm chart repository for home lab smart home and media services, hosted on GitHub Pages.

## 📚 Documentation

- **[Quick Start Guide](./QUICKSTART.md)** - Get started in 5 minutes ⚡
- **[Lens Deployment Guide](./LENS_DEPLOYMENT_GUIDE.md)** - Complete Lens workflows and troubleshooting 🎨
- **[Setup Checklist](./SETUP_CHECKLIST.md)** - Verify your configuration ✅
- **[Workflow Comparison](./WORKFLOW_COMPARISON.md)** - Local vs. Lens deployment strategies 🔄
- **[Architecture Guide](.github/copilot-instructions.md)** - Chart patterns and conventions 🏗️

## Repository URL

```
https://billy27607.github.io/my-helm-charts
```

## Usage

### Add to Lens (Kubernetes IDE)

1. Open **Lens**
2. Connect to your cluster
3. Navigate to **Helm** > **Charts**
4. Click **⚙️ (gear icon)** or **Add Repository**
5. Enter:
   - **Name**: `my-charts` (or any name you prefer)
   - **URL**: `https://billy27607.github.io/my-helm-charts`
6. Click **Add** or **Save**
7. The repository will appear in your Charts list
8. Click on any chart to view versions and deploy with custom values

### Add to Helm CLI

```bash
helm repo add my-charts https://billy27607.github.io/my-helm-charts
helm repo update
helm search repo my-charts/
```

### Deploy a Chart from Lens

1. Go to **Helm** > **Charts** in Lens
2. Select **my-charts** repository from the dropdown
3. Click on a chart (e.g., `scrypted`, `homebridge`)
4. Click **Install** button
5. Configure:
   - **Release Name**: e.g., `scrypted-prod`
   - **Namespace**: e.g., `ourplan`
   - **Values**: Edit YAML to customize settings
6. Click **Install**

### Deploy a Chart from Helm CLI

```bash
# Install with default values
helm install my-release my-charts/scrypted --namespace ourplan --create-namespace

# Install with custom values file
helm install my-release my-charts/scrypted -f custom-values.yaml --namespace ourplan

# Upgrade existing release
helm upgrade my-release my-charts/scrypted --namespace ourplan --set hostNetwork=false
```

## Available Charts

| Chart | Description | Version |
|-------|-------------|---------|
| [auto-mount](./charts/auto-mount) | Automatic NFS mount manager | 0.1.86 |
| [avahi-daemon](./charts/avahi-daemon) | Avahi mDNS/DNS-SD daemon | 0.1.0 |
| [firefox-remote](./charts/firefox-remote) | Remote Firefox via noVNC | 0.1.0 |
| [hdhomerun-app-proxy](./charts/hdhomerun-app-proxy) | HDHomeRun app protocol proxy | 0.1.0 |
| [hdhomerun-tuner-proxy](./charts/hdhomerun-tuner-proxy) | HDHomeRun tuner proxy | 0.1.0 |
| [homebridge](./charts/homebridge) | HomeKit bridge with Mosquitto MQTT | 0.5.0 |
| [iperf3](./charts/iperf3) | Network performance testing | 0.2.0 |
| [mdns-reflector](./charts/mdns-reflector) | Selective mDNS/Bonjour reflector | 0.3.6 |
| [octoprint](./charts/octoprint) | 3D printer control with webcam | 0.1.0 |
| [prometheus](./charts/prometheus) | Prometheus monitoring | 0.1.0 |
| [rtl-sdr](./charts/rtl-sdr) | RTL-SDR radio receiver | 0.1.0 |
| [scrypted](./charts/scrypted) | NVR home video integration | 0.1.0 |
| [website-monitor](./charts/website-monitor) | Website availability monitor | 0.1.0 |
| [xcarve](./charts/xcarve) | CNCjs with MJPG-Streamer | 0.2.0 |

## Development

### Local Testing (Before Publishing)

Use the provided k8s-helpers.sh script for local development:

```bash
# Install chart from local directory
./scripts/k8s-helpers.sh helm-install scrypted test-release --namespace=ourplan

# Upgrade with custom values
./scripts/k8s-helpers.sh helm-upgrade scrypted test-release --namespace=ourplan --set hostNetwork=false

# Check status and logs
./scripts/k8s-helpers.sh helm-status test-release --namespace=ourplan
./scripts/k8s-helpers.sh helm-logs test-release --namespace=ourplan
```

Or use VS Code tasks (Run Task → helm: Install/Upgrade/Status/Logs).

### Publishing New Charts

1. Create a new directory under `charts/` with your chart files
2. Ensure `Chart.yaml` has proper version (semver: `0.1.0`, `1.0.0`, etc.)
3. Commit and push to `main` branch:
   ```bash
   git add charts/my-new-chart
   git commit -m "Add my-new-chart v0.1.0"
   git push origin main
   ```
4. GitHub Actions will automatically:
   - Package the chart using `helm package`
   - Create a GitHub Release with the chart archive
   - Update the Helm repository index on `gh-pages` branch
5. Charts become available at: `https://billy27607.github.io/my-helm-charts`

### Updating Existing Charts

1. Edit chart files under `charts/<chart-name>/`
2. **Bump the version** in `Chart.yaml` (e.g., `0.1.0` → `0.1.1` or `0.2.0`)
3. Commit and push to `main`:
   ```bash
   git add charts/scrypted
   git commit -m "Update scrypted chart to v0.2.0"
   git push origin main
   ```
4. The new version will be automatically published
5. In Lens, refresh your repositories to see the new version

**Important**: The workflow skips already-published versions (`skip_existing: true`), so you **must** bump the version number for changes to be released.

### Chart Structure

```
charts/
└── my-chart/
    ├── Chart.yaml          # Metadata and version
    ├── values.yaml         # Default configuration
    ├── README.md           # Chart documentation (optional)
    └── templates/
        ├── _helpers.tpl    # Template helpers
        ├── deployment.yaml
        ├── service.yaml
        └── ...
```

## Repository Management

### Enabling GitHub Pages (One-Time Setup)

If not already enabled:

1. Go to your repository on GitHub
2. Navigate to **Settings** > **Pages**
3. Under "Source", select:
   - **Branch**: `gh-pages`
   - **Folder**: `/ (root)`
4. Click **Save**
5. GitHub Pages will be available at: `https://billy27607.github.io/my-helm-charts`

### Workflow Permissions

The `.github/workflows/release-charts.yaml` requires:
- `contents: write` - to create releases
- `pages: write` - to publish to GitHub Pages
- `id-token: write` - for GitHub OIDC authentication

These are already configured in the workflow file.

### Checking Published Charts

```bash
# List all published releases
curl https://billy27607.github.io/my-helm-charts/index.yaml

# Or use Helm
helm repo add my-charts https://billy27607.github.io/my-helm-charts
helm search repo my-charts/ --versions
```

## Architecture

This repository is designed for **edge/home lab deployments** with:
- Single-node Kubernetes clusters
- Hardware device access (USB, GPU, serial)
- `hostNetwork` mode for IoT device discovery (mDNS, SSDP)
- `hostPath` persistence (local storage)

See [.github/copilot-instructions.md](.github/copilot-instructions.md) for detailed architecture patterns and conventions.

## Support

For chart-specific documentation, see individual chart README files in `charts/<chart-name>/README.md`.

## GitHub Setup

After pushing to GitHub:

1. Go to **Settings** > **Pages**
2. Set **Source** to **Deploy from a branch**
3. Select the `gh-pages` branch and `/ (root)` folder
4. Save

The chart-releaser GitHub Action will automatically create the `gh-pages` branch on the first release.
