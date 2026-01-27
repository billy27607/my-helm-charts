# Website Monitor

A Kubernetes CronJob-based website monitoring solution that checks site availability and reports when sites are down.

## Features

- 🔍 Multiple website monitoring with configurable URLs
- ⏰ Customizable check intervals (cron-based)
- 📊 HTTP status code validation- 🔔 **GitHub push notifications** via automatic issue creation- � SMS notifications via email gateway (AT&T, Verizon, T-Mobile)
- �🔔 Webhook notifications when sites are down
- 📝 Detailed logging to stdout
- ⚡ Lightweight (uses curl)

## Configuration

### Basic Setup

```yaml
monitors:
  - name: mysite
    url: https://mysite.com
    method: GET
    expectedStatus: 200
    timeout: 10
    enabled: true

schedule: "*/5 * * * *"  # Every 5 minutes
```

### GitHub Push Notifications (Recommended!)

Get **instant push notifications on your phone** when sites go down by creating GitHub issues:

**1. Create a Personal Access Token**:
   - Go to: https://github.com/settings/tokens
   - Click "Generate new token (classic)"
   - Name: "Website Monitor"
   - Select scope: `repo` (Full control of private repositories)
   - Click "Generate token" and copy it

**2. Configure in values**:
```yaml
notifications:
  github:
    enabled: true
    token: "ghp_your_token_here"
    repo: "billy27607/my-helm-charts"
    labels: ["alert", "website-down"]
    autoClose: true  # Auto-close issue when site is back up
```

**How it works**:
- 🚨 Creates a GitHub issue when site goes down → **Push notification to your phone**
- 📱 You can see details, history, and track incidents
- ✅ Automatically closes the issue when site is back up
- 🔄 Adds comments if site stays down on subsequent checks

**3. Make sure GitHub mobile app is set up**:
   - Install GitHub app on your phone
   - Enable notifications in Settings → Notifications → Issues

### Webhook Notifications

Send alerts to Slack, Discord, or custom webhooks:

```yaml
notifications:
  webhook:
    enabled: true
    url: "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
    method: POST
```

The webhook receives JSON:
```json
{
  "status": "down",
  "site": "mysite",
  "url": "https://mysite.com",
  "http_code": "503",
  "timestamp": "2026-01-27T10:30:00Z"
}
```

### SMS Notifications via Email Gateway

Get text messages when sites go down using carrier email-to-SMS gateways:

**1. Set up SMTP credentials** (using Gmail as example):
   - Enable 2-factor auth on Gmail
   - Create App Password at: https://myaccount.google.com/apppasswords
   - Select "Mail" and "Other (Custom name)"

**2. Create private values file**:
```bash
cd charts/website-monitor
cp values-example.yaml values-private.yaml
# Edit values-private.yaml with your credentials
```

**3. Configure SMS settings**:
```yaml
notifications:
  sms:
    enabled: true
    to: "9195223015@txt.att.net"  # Your phone number
    from: "your-email@gmail.com"
    smtp:
      host: "smtp.gmail.com"
      port: 587
      username: "your-email@gmail.com"
      password: "your-app-password"
      useTLS: true
```

**Email-to-SMS Gateway Addresses**:
- AT&T: `number@txt.att.net`
- Verizon: `number@vtext.com`
- T-Mobile: `number@tmomail.net`
- Sprint: `number@messaging.sprintpcs.com`

**4. Deploy with private values**:
```bash
helm install website-monitor . -f values-private.yaml --namespace=ourplan
```

## Installation

```bash
# Install with default config
helm install website-monitor ./website-monitor

# Install with custom values
helm install website-monitor ./website-monitor \
  --set monitors[0].url=https://example.com \
  --set schedule="*/1 * * * *"
```

## Viewing Logs

```bash
# View recent job logs
kubectl logs -l app.kubernetes.io/name=website-monitor --tail=50

# Watch live logs
kubectl logs -l app.kubernetes.io/name=website-monitor -f
```

## Monitoring Multiple Sites

```yaml
monitors:
  - name: production
    url: https://prod.example.com
    expectedStatus: 200
    enabled: true
  
  - name: staging
    url: https://staging.example.com
    expectedStatus: 200
    enabled: true
  
  - name: api
    url: https://api.example.com/health
    expectedStatus: 200
    enabled: true
```

## Cron Schedule Examples

```yaml
schedule: "*/1 * * * *"     # Every minute
schedule: "*/5 * * * *"     # Every 5 minutes
schedule: "0 * * * *"       # Every hour
schedule: "*/30 * * * *"    # Every 30 minutes
```
