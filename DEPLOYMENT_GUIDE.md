# Contoso Web on Azure — Deployment Guide

## What Will Be Created

| Resource | Type | Purpose |
|----------|------|---------|
| `asp-contoso-web-prod` | App Service Plan (B1) | Linux compute for the web app |
| `app-contoso-web-prod-*` | Web App (Node 20) | Hosts the Next.js application |
| `appi-contoso-web-prod` | Application Insights | Request tracing, error tracking |
| `log-contoso-web-prod` | Log Analytics Workspace | Centralized log storage |

## Deployment Methods

### Method 1: GitHub Actions (Recommended)

Push to `main` triggers automatic build and deploy. See [README.md](README.md#quick-start).

### Method 2: Azure CLI (Manual)

```bash
az login
az group create -n rg-contoso-web-prod -l eastus
az deployment group create -g rg-contoso-web-prod --template-file infra/main.bicep
cd app && npm ci && npm run build && cd ..
az webapp deploy -g rg-contoso-web-prod \
  --name $(az webapp list -g rg-contoso-web-prod --query '[0].name' -o tsv) \
  --src-path app/ --type zip
```

## Monitoring

### View Logs

```bash
# Stream live logs
az webapp log tail -g rg-contoso-web-prod -n <app-name>

# View in Azure Portal
# → App Service → Monitoring → Log stream
# → Application Insights → Investigate → Failures / Performance
```

### Health Check

The app has a health check configured at `/`. Azure automatically restarts unhealthy instances.

### Application Insights

Access via Azure Portal → Application Insights → `appi-contoso-web-prod`:
- **Live Metrics** — real-time request/response
- **Failures** — error tracking with stack traces
- **Performance** — response times and dependencies
- **Availability** — uptime monitoring

## Configuration

### App Settings

Modify via Azure Portal → App Service → Configuration, or CLI:

```bash
az webapp config appsettings set -g rg-contoso-web-prod -n <app-name> \
  --settings KEY=value
```

### Scale Up

Change the App Service Plan tier in `infra/main.bicep`:

```bicep
sku: {
  name: 'B2'  // or 'S1' for staging slots
  tier: 'Basic'  // or 'Standard'
}
```

Then redeploy: `az deployment group create ...`

### Custom Domain

```bash
az webapp config hostname add -g rg-contoso-web-prod \
  -n <app-name> --hostname www.contoso.com

# Free managed certificate
az webapp config ssl create -g rg-contoso-web-prod \
  -n <app-name> --hostname www.contoso.com
```

## Security

| Control | Status |
|---------|--------|
| HTTPS Only | ✅ Enforced |
| TLS Version | ✅ 1.2 minimum |
| FTP | ✅ Disabled |
| Managed Identity | ✅ System-assigned |
| SSH (port 22) | ✅ Not exposed |
| Credentials in code | ✅ None |

## Troubleshooting

### App Returns 503

```bash
# Check app logs
az webapp log tail -g rg-contoso-web-prod -n <app-name>

# Restart the app
az webapp restart -g rg-contoso-web-prod -n <app-name>
```

### Deployment Fails

```bash
# Check deployment logs
az webapp deployment list-publishing-profiles -g rg-contoso-web-prod -n <app-name>

# Check GitHub Actions workflow run for build errors
```

### Slow Performance

- Scale up: change B1 → B2 or S1 in Bicep
- Check App Insights → Performance for bottlenecks
- Enable `alwaysOn` (already enabled in B1+)

## Cost Control

- B1 plan: ~$13/month (sufficient for low-medium traffic)
- App Insights: Free up to 5GB/month ingestion
- Log Analytics: Free up to 5GB/month
- Scale down to F1 (free) for dev/test (remove `alwaysOn`)

## Cleanup

```bash
# Delete everything
az group delete -n rg-contoso-web-prod --yes --no-wait
```
