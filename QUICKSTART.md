# Quick Start: Using Lens with Your Helm Charts

## TL;DR

Your Helm charts are automatically published to GitHub Pages and can be deployed via Lens. Here's what you need to know:

**Repository URL**: `https://billy27607.github.io/my-helm-charts`

**How it works**:
1. Edit charts locally
2. Bump version in Chart.yaml
3. Push to GitHub (main branch)
4. GitHub Actions auto-publishes to GitHub Pages
5. Deploy via Lens GUI

## Step 1: Verify GitHub Pages is Enabled

1. Visit: https://github.com/billy27607/my-helm-charts/settings/pages
2. Ensure settings are:
   - **Source**: Deploy from a branch
   - **Branch**: `gh-pages` / (root)

If `gh-pages` doesn't exist yet, push any change to trigger the workflow.

## Step 2: Test Your Repository

Run the VS Code task:
- **Command Palette** (Cmd+Shift+P) → **Run Task** → **repo: Verify Published Charts**

Or manually:
```bash
helm repo add my-charts https://billy27607.github.io/my-helm-charts
helm repo update
helm search repo my-charts/
```

You should see all 14 charts listed.

## Step 3: Add Repository to Lens

1. **Open Lens** and connect to your cluster
2. Click **Helm** in sidebar → **Charts** tab
3. Click **⚙️ (gear icon)** 
4. Click **Add Repository**
5. Enter:
   - **Name**: `my-charts`
   - **URL**: `https://billy27607.github.io/my-helm-charts`
6. Click **Add**

## Step 4: Deploy Your First Chart

### Easy Test: Deploy iperf3

1. In Lens, go to **Helm** → **Charts**
2. Select `my-charts` from dropdown
3. Click **iperf3** chart
4. Click **Install** button
5. Configure:
   ```
   Release Name: iperf3-test
   Namespace: test
   ```
6. Click **Install** (keep default values)
7. Go to **Workloads** → **Pods** to watch deployment
8. Wait for pod to show **Running**

### Deploy Production Chart (e.g., Scrypted)

1. In Lens: **Helm** → **Charts** → `my-charts` → **scrypted**
2. Click **Install**
3. Configure:
   ```
   Release Name: scrypted
   Namespace: ourplan
   ```
4. Edit Values YAML:
   ```yaml
   hostNetwork: true
   
   devices:
     usb: true  # Coral TPU
     dri: true  # Intel QuickSync
   
   persistence:
     enabled: true
     type: hostPath
     hostPath: /mnt/nvr/scrypted
   
   intelGpu:
     enabled: true
   
   securityContext:
     privileged: true
   ```
5. Click **Install**
6. Monitor in **Workloads** → **Pods**

## Step 5: Making Changes

### Update Chart Code

1. Edit chart files locally:
   ```bash
   cd charts/scrypted
   # Edit templates, values.yaml, etc.
   ```

2. **IMPORTANT**: Bump version in Chart.yaml:
   ```yaml
   version: 0.1.0  # Change to 0.1.1 or 0.2.0
   ```

3. Commit and push:
   ```bash
   git add charts/scrypted
   git commit -m "Update scrypted to v0.1.1: add feature X"
   git push origin main
   ```

4. Wait 1-3 minutes for GitHub Actions to complete:
   - Monitor at: https://github.com/billy27607/my-helm-charts/actions

5. In Lens:
   - Refresh repositories (or wait for auto-refresh)
   - Go to **Helm** → **Releases**
   - Find your release → Click **Upgrade**
   - Select new version from dropdown
   - Click **Upgrade**

## Common Workflows

### Local Test → Publish → Deploy

```bash
# 1. Test locally first
./scripts/k8s-helpers.sh helm-install scrypted test-release --namespace=test
./scripts/k8s-helpers.sh helm-logs test-release --namespace=test

# 2. Once working, bump version and push
# Edit charts/scrypted/Chart.yaml: version: 0.1.1
git add charts/scrypted
git commit -m "Release scrypted v0.1.1"
git push origin main

# 3. Wait for GitHub Actions, then deploy via Lens GUI
```

### Quick Config Change via Lens

1. **Helm** → **Releases** → Select release
2. Click **Upgrade**
3. Edit values YAML (e.g., change hostNetwork to false)
4. Click **Upgrade**
5. No need to change chart version for config-only changes

### View Logs and Debug

1. **Workloads** → **Pods** → Click your pod
2. **Logs** tab - view container logs
3. **Events** tab - see deployment issues
4. **Pod Shell** icon - exec into container
5. Use filters and search in logs

## VS Code Tasks Reference

New tasks added for repository management:

| Task | Purpose |
|------|---------|
| **repo: Verify Published Charts** | Test that charts are published correctly |
| **repo: Show Chart Details** | View chart info and default values |
| **repo: Lint All Charts** | Validate all charts before pushing |
| **repo: Open GitHub Actions** | Open workflow status in browser |
| **repo: Open GitHub Pages Settings** | Open Pages configuration |

Run via: **Cmd+Shift+P** → **Run Task** → Select task

## Troubleshooting

### Charts not showing in Lens
- Remove and re-add repository in Lens
- Verify URL: `https://billy27607.github.io/my-helm-charts`
- Check GitHub Actions completed successfully

### New version not appearing
- Did you bump version in Chart.yaml?
- Check GitHub Actions: https://github.com/billy27607/my-helm-charts/actions
- Workflow only triggers on changes to `charts/**` paths
- Wait 2-5 minutes for GitHub Pages to update

### Deployment fails in Lens
- Click pod in **Workloads** → **Events** tab for errors
- Common issues:
  - **ImagePullBackOff**: Image doesn't exist
  - **Port conflicts**: Another service on same hostPort
  - **Pending**: Resource constraints or storage issues
  - **CrashLoopBackOff**: Check pod logs for startup errors

### Can't access deployed service
- Check if `hostNetwork: true` is set
- Verify pod is **Running** in Workloads view
- Check service ports in **Network** → **Services**
- For device access, ensure `privileged: true`

## Key Differences from Old Workflow

| Old (k8s-helpers.sh) | New (Lens + GitHub) |
|----------------------|---------------------|
| Local chart files | Published chart repository |
| Command line `helm-install` | GUI-based deployment |
| Manual version tracking | Semantic versioning + releases |
| Local-only testing | Test locally, deploy from registry |
| Script-based management | Visual cluster management |

**You can still use both!**
- Use k8s-helpers.sh for rapid local development/testing
- Use Lens for production deployments from published charts

## Next Steps

1. ✅ **Verify setup**: Run "repo: Verify Published Charts" task
2. ✅ **Test deployment**: Deploy iperf3 chart via Lens
3. ✅ **Update a chart**: Make a change, bump version, push
4. ✅ **Deploy production**: Use Lens to deploy your main services
5. 📚 **Read full docs**: See [LENS_DEPLOYMENT_GUIDE.md](./LENS_DEPLOYMENT_GUIDE.md)

## Additional Resources

- [Lens Deployment Guide](./LENS_DEPLOYMENT_GUIDE.md) - Complete Lens workflows
- [Setup Checklist](./SETUP_CHECKLIST.md) - Verify everything is configured
- [Repository README](./README.md) - Full documentation
- [Architecture Guide](.github/copilot-instructions.md) - Chart patterns and conventions

---

**Questions?**
- Check [LENS_DEPLOYMENT_GUIDE.md](./LENS_DEPLOYMENT_GUIDE.md) for detailed walkthroughs
- Use VS Code tasks for quick testing and validation
- Monitor GitHub Actions for publishing status
