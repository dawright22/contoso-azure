# Contoso Web on Azure

Deploy the **Contoso Outdoors** website to Azure App Service using **Bicep** (infrastructure) and **GitHub Actions** (CI/CD).

Migrated from AWS (EC2 + ALB) to Azure App Service for **~55% cost reduction**.

## Architecture

```
┌──────────────────────────────────────────────────────┐
│         Azure App Service (HTTPS, built-in LB)       │
│         Plan: B1 Linux | Node.js 20 LTS              │
├──────────────────────────────────────────────────────┤
│  • Next.js Application (SSR)                         │
│  • Managed Identity (system-assigned)                │
│  • Health checks enabled                             │
│  • HTTPS-only, TLS 1.2, FTP disabled                 │
├──────────────────────────────────────────────────────┤
│  Application Insights + Log Analytics (monitoring)   │
└──────────────────────────────────────────────────────┘
```

## Cost Comparison

| Component | AWS (was) | Azure (now) |
|-----------|-----------|-------------|
| Compute | EC2 t3.micro: $8 | App Service B1: $13 |
| Load Balancer | ALB: $15 | Built-in: $0 |
| Storage | S3: $1 | Not needed: $0 |
| Monitoring | — | App Insights: Free |
| **Total** | **~$34/month** | **~$13/month** |

## What's Improved

- ✅ **Built-in HTTPS** with managed certificates (was HTTP-only)
- ✅ **Built-in load balancing** (no separate ALB to manage)
- ✅ **CI/CD pipeline** — push to main auto-deploys (was manual `terraform apply`)
- ✅ **Application monitoring** with App Insights (was none)
- ✅ **Health checks** built-in (was manual SSH + PM2)
- ✅ **Managed Identity** for Azure access (no stored credentials)
- ✅ **Security hardened** — HTTPS-only, TLS 1.2, FTP disabled

## Prerequisites

1. Azure subscription
2. GitHub repo with Actions enabled
3. Azure CLI (`az`) for initial OIDC setup

## Quick Start

### 1. Set Up OIDC Authentication

```bash
# Create Azure AD App Registration
az ad app create --display-name "contoso-azure-deploy"

# Note the appId, then create a service principal
az ad sp create --id <APP_ID>

# Add federated credential for GitHub Actions
az ad app federated-credential create --id <APP_ID> --parameters '{
  "name": "github-actions-main",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:dawright22/contoso-azure:ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"]
}'

# Grant Contributor role on your subscription
az role assignment create \
  --assignee <APP_ID> \
  --role Contributor \
  --scope /subscriptions/<SUBSCRIPTION_ID>
```

### 2. Add GitHub Secrets

In your repo → Settings → Secrets → Actions, add:

| Secret | Value |
|--------|-------|
| `AZURE_CLIENT_ID` | App Registration client ID |
| `AZURE_TENANT_ID` | Azure AD tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Target subscription ID |

### 3. Deploy

```bash
git push origin main
# GitHub Actions will automatically build and deploy
```

### 4. Access Your App

Check the GitHub Actions run output for the URL, or:

```bash
az webapp show -g rg-contoso-web-prod --query defaultHostName -o tsv
```

## Manual Deployment (without CI/CD)

```bash
# Login to Azure
az login

# Create resource group
az group create -n rg-contoso-web-prod -l eastus

# Deploy infrastructure
az deployment group create \
  -g rg-contoso-web-prod \
  --template-file infra/main.bicep \
  --parameters environment=prod

# Build the app
cd app && npm ci && npm run build && cd ..

# Deploy the app
az webapp deploy \
  --resource-group rg-contoso-web-prod \
  --name $(az webapp list -g rg-contoso-web-prod --query '[0].name' -o tsv) \
  --src-path app/ \
  --type zip
```

## File Structure

```
.
├── infra/
│   └── main.bicep               # Azure infrastructure (App Service, App Insights)
├── .github/
│   └── workflows/
│       └── deploy.yml            # CI/CD: build → deploy to Azure
├── app/                          # Next.js application source
├── DEPLOYMENT_GUIDE.md           # Detailed deployment guide
├── CHAT_DISABLING_OPTIONS.md     # Chat configuration options
└── README.md                     # This file
```

## Chat Functionality

**Status**: Disabled by default (no AI endpoints configured).

The website displays fully functional except for chat features. To enable chat:
1. Set up Azure AI services (Search, OpenAI, etc.)
2. Add environment variables via App Service configuration
3. No restart needed — App Service picks up config changes

## Cleanup

```bash
az group delete -n rg-contoso-web-prod --yes
```

## Support

- [Azure App Service Docs](https://learn.microsoft.com/azure/app-service/)
- [Bicep Docs](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Contoso Web App](https://github.com/Azure-Samples/contoso-web)
