# Workflow Comparison: Local vs. Lens Deployment

This guide helps you understand when to use local k8s-helpers.sh scripts versus Lens deployments from the published chart repository.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Development Flow                         │
└─────────────────────────────────────────────────────────────┘

LOCAL DEVELOPMENT                    PRODUCTION DEPLOYMENT
─────────────────                    ─────────────────────

1. Edit charts locally              1. Push to GitHub (main)
   └─ charts/scrypted/                 └─ git push origin main
      ├─ Chart.yaml                       
      ├─ values.yaml              2. GitHub Actions runs
      └─ templates/                  └─ Packages charts
                                        └─ Publishes to gh-pages
2. Test with k8s-helpers.sh            
   └─ ./scripts/k8s-helpers.sh      3. Charts available at:
      helm-install scrypted test      └─ billy27607.github.io/
                                          my-helm-charts
3. Iterate quickly
   └─ helm-upgrade                  4. Deploy via Lens GUI
   └─ helm-logs                        └─ Helm → Charts
   └─ helm-restart                        └─ Select & Install

4. Once stable → publish
   └─ Bump version
   └─ Push to GitHub
```

## Method 1: Local Development (k8s-helpers.sh)

**Best for:**
- 🚀 Rapid development and testing
- 🔧 Iterating on chart templates
- 🐛 Debugging chart issues
- 📝 Testing value combinations
- 🎯 Quick experiments

**Workflow:**
```bash
# Install from local directory
./scripts/k8s-helpers.sh helm-install scrypted test-release --namespace=test

# Make changes to templates
vim charts/scrypted/templates/deployment.yaml

# Upgrade without version bump
./scripts/k8s-helpers.sh helm-upgrade scrypted test-release --namespace=test

# Check logs immediately
./scripts/k8s-helpers.sh helm-logs test-release --namespace=test

# Clean up
./scripts/k8s-helpers.sh helm-uninstall test-release --namespace=test
```

**Advantages:**
- ✅ Instant feedback loop
- ✅ No version bump required
- ✅ No GitHub push needed
- ✅ Script automation
- ✅ Command-line power users

**Disadvantages:**
- ❌ Only works on your machine
- ❌ No version control of deployments
- ❌ Harder to share with team
- ❌ CLI-based (less visual)

## Method 2: Lens Deployment (Published Charts)

**Best for:**
- 🏢 Production deployments
- 👥 Team collaboration
- 📦 Version management
- 🎨 Visual cluster management
- 📊 Monitoring and observability
- 🔄 Rollbacks and upgrades

**Workflow:**
```bash
# 1. Develop and test locally first (see Method 1)

# 2. Once ready, bump version
vim charts/scrypted/Chart.yaml  # 0.1.0 → 0.1.1

# 3. Commit and push
git add charts/scrypted
git commit -m "Release scrypted v0.1.1: add feature X"
git push origin main

# 4. Wait for GitHub Actions (1-3 minutes)
# Monitor at: https://github.com/billy27607/my-helm-charts/actions

# 5. Deploy via Lens GUI:
#    - Helm → Charts → my-charts → scrypted
#    - Select version 0.1.1
#    - Install with production values
```

**Advantages:**
- ✅ Visual interface (easier for complex clusters)
- ✅ Versioned deployments
- ✅ Team can deploy same version
- ✅ Built-in monitoring tools
- ✅ Easy rollback to previous versions
- ✅ Browse charts and values visually
- ✅ Works from any machine with Lens

**Disadvantages:**
- ❌ Requires version bump and push
- ❌ Slower iteration (1-3 min publish delay)
- ❌ Need GitHub Actions to pass
- ❌ Requires Lens installation

## Decision Matrix

| Scenario | Recommended Method |
|----------|-------------------|
| **Testing new chart** | Local (k8s-helpers.sh) |
| **Debugging template issues** | Local (k8s-helpers.sh) |
| **Trying different values** | Local (k8s-helpers.sh) |
| **Deploying to production** | Lens (published) |
| **Deploying to remote cluster** | Lens (published) |
| **Team deployment** | Lens (published) |
| **Need visual monitoring** | Lens (published) |
| **Version controlled deployment** | Lens (published) |
| **Quick restart** | Either (Lens: GUI, Local: helm-restart) |
| **View logs** | Either (Lens: GUI, Local: helm-logs) |

## Hybrid Workflow (Recommended)

Combine both methods for optimal development:

### Phase 1: Development & Testing (Local)
```bash
# Rapid iteration
cd my-helm-charts

# Test new feature
./scripts/k8s-helpers.sh helm-install scrypted dev-test --namespace=dev

# Make changes
vim charts/scrypted/templates/deployment.yaml

# Quick upgrade
./scripts/k8s-helpers.sh helm-upgrade scrypted dev-test --namespace=dev

# Check logs
./scripts/k8s-helpers.sh helm-logs dev-test --namespace=dev

# Repeat until working perfectly
```

### Phase 2: Publish (GitHub)
```bash
# Once stable, version it
vim charts/scrypted/Chart.yaml  # Bump version

git add charts/scrypted
git commit -m "Release scrypted v0.2.0: hardware transcoding support"
git push origin main

# Wait for GitHub Actions to complete
```

### Phase 3: Production Deployment (Lens)
```
1. Open Lens
2. Helm → Charts → my-charts → scrypted
3. Select version 0.2.0
4. Install with production values:
   - Release: scrypted-prod
   - Namespace: ourplan
   - Custom values for production
5. Monitor in Workloads view
6. Check logs if needed
```

### Phase 4: Ongoing Management (Lens)
```
- Monitor pod health in Workloads
- View metrics and resources
- Check logs when issues arise
- Upgrade to new versions as released
- Rollback if problems occur
```

## Feature Comparison

| Feature | k8s-helpers.sh | Lens + Published Charts |
|---------|---------------|-------------------------|
| **Visual Interface** | ❌ CLI only | ✅ Full GUI |
| **Installation Speed** | ⚡ Instant | 🐌 After publish (1-3 min) |
| **Version Control** | ❌ Manual | ✅ Automatic |
| **Team Sharing** | ❌ Local only | ✅ Published repository |
| **Cluster Monitoring** | ❌ Separate tools | ✅ Built-in |
| **Pod Logs** | ✅ `helm-logs` | ✅ GUI with search |
| **Shell Access** | ⚙️ Manual kubectl | ✅ Click to exec |
| **Resource Graphs** | ❌ | ✅ CPU/Memory charts |
| **Rollback** | ⚙️ Manual version | ✅ Click previous version |
| **Multi-cluster** | ⚙️ Manual context | ✅ Switch clusters easily |
| **Values Preview** | ⚙️ helm template | ✅ Visual diff |
| **Chart Search** | ❌ | ✅ Search all repos |
| **Automation** | ✅ Scripts | ⚙️ Less automation |

## VS Code Tasks vs Lens

### VS Code Tasks (Local)
Best for developers who:
- Live in the terminal/editor
- Want keyboard-driven workflow
- Prefer automation and scripting
- Work on one machine

**Example:**
```
Cmd+Shift+P → Run Task → helm: Install
  → Select chart: scrypted
  → Release name: test
  → Namespace: dev
  → Extra args: --set hostNetwork=false

Result: Instant deployment from local files
```

### Lens (Published)
Best for operators who:
- Prefer visual interfaces
- Manage multiple clusters
- Need monitoring dashboards
- Collaborate with team

**Example:**
```
Lens → Helm → Charts → my-charts → scrypted
  → Install
  → Configure in form/YAML editor
  → Click Install

Result: Versioned deployment with visual feedback
```

## When to Use Each Method

### Use k8s-helpers.sh when:
- 🔨 Building a new chart
- 🐛 Debugging template syntax
- 🧪 Testing different configurations
- 🚀 Need fast iteration cycles
- 📝 Writing documentation (testing examples)
- 🔧 Local development only

### Use Lens when:
- 🏢 Deploying to production
- 👀 Monitoring cluster health
- 📊 Viewing resource usage
- 🔄 Managing multiple releases
- 👥 Working with a team
- 🎯 Need visual context
- 🌍 Managing remote clusters

## Migration Path

If you're currently using only local scripts:

### Week 1: Setup
- ✅ Verify GitHub Pages enabled
- ✅ Test repository: `helm search repo my-charts/`
- ✅ Add repo to Lens
- ✅ Deploy one test chart via Lens

### Week 2: Parallel Operation
- 🔧 Continue local development as usual
- 📦 Publish stable versions to GitHub
- 🎨 Use Lens for monitoring existing deployments
- 📝 Get comfortable with Lens UI

### Week 3: Hybrid Workflow
- ⚡ Local for development/testing
- 🚀 Publish when ready
- 🏢 Deploy production via Lens
- 📊 Monitor in Lens

### Week 4+: Production Ready
- 🎯 Standard workflow established
- 📦 All production via versioned charts
- 🔧 Local only for development
- 👥 Team can deploy from Lens

## Quick Reference

### Local Development Commands
```bash
# Install
./scripts/k8s-helpers.sh helm-install <chart> <release> --namespace=<ns>

# Upgrade
./scripts/k8s-helpers.sh helm-upgrade <chart> <release> --namespace=<ns> --set key=value

# Logs
./scripts/k8s-helpers.sh helm-logs <release> --namespace=<ns>

# Status
./scripts/k8s-helpers.sh helm-status <release> --namespace=<ns>

# Restart
./scripts/k8s-helpers.sh helm-restart <release> --namespace=<ns>

# Uninstall
./scripts/k8s-helpers.sh helm-uninstall <release> --namespace=<ns>
```

### Lens Operations
```
Install:    Helm → Charts → Select → Install
Upgrade:    Helm → Releases → Select → Upgrade
Logs:       Workloads → Pods → Select → Logs
Shell:      Workloads → Pods → Select → Pod Shell icon
Status:     Workloads → Pods → Select → View details
Events:     Workloads → Pods → Select → Events
Uninstall:  Helm → Releases → Select → ⋮ → Uninstall
```

## Conclusion

**Use both methods strategically:**

- **k8s-helpers.sh**: Your development/testing toolbelt
  - Fast, flexible, automation-friendly
  
- **Lens + Published Charts**: Your production deployment platform
  - Visual, collaborative, version-controlled

The goal is **not** to replace one with the other, but to use the right tool for the right job at the right time in your workflow.
