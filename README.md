# My Helm Charts

A Helm chart repository hosted on GitHub Pages.

## Usage

### Add this repository to Helm

```bash
helm repo add my-charts https://<your-github-username>.github.io/my-helm-charts
helm repo update
```

### Add to Headlamp

1. Open Headlamp
2. Go to **Settings** > **Helm Repositories**
3. Click **Add Repository**
4. Enter:
   - **Name**: `my-charts`
   - **URL**: `https://<your-github-username>.github.io/my-helm-charts`
5. Click **Save**

## Available Charts

| Chart | Description |
|-------|-------------|
| [iperf3](./charts/iperf3) | Network performance testing tool |
| [firefox-remote](./charts/firefox-remote) | Remote Firefox via noVNC with ingress-ready defaults |

## Development

### Adding a new chart

1. Create a new directory under `charts/`
2. Add your chart files (`Chart.yaml`, `values.yaml`, `templates/`)
3. Push to `main` branch
4. The GitHub Action will automatically package and release the chart

### Chart structure

```
charts/
└── my-chart/
    ├── Chart.yaml
    ├── values.yaml
    └── templates/
        ├── _helpers.tpl
        ├── deployment.yaml
        └── service.yaml
```

## GitHub Setup

After pushing to GitHub:

1. Go to **Settings** > **Pages**
2. Set **Source** to **Deploy from a branch**
3. Select the `gh-pages` branch and `/ (root)` folder
4. Save

The chart-releaser GitHub Action will automatically create the `gh-pages` branch on the first release.
