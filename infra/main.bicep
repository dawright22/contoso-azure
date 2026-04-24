// Contoso Web on Azure — App Service (B1, Linux, Node 20)
// Lowest-cost production deployment with monitoring and security hardening

targetScope = 'resourceGroup'

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Application name used for resource naming')
param appName string = 'contoso-web'

@description('Environment (dev, staging, prod)')
@allowed(['dev', 'staging', 'prod'])
param environment string = 'prod'

@description('Node.js environment')
param nodeEnv string = 'production'

// --- Naming ---
var suffix = '${appName}-${environment}'
var appServicePlanName = 'asp-${suffix}'
var webAppName = 'app-${suffix}-${uniqueString(resourceGroup().id)}'
var appInsightsName = 'appi-${suffix}'
var logAnalyticsName = 'log-${suffix}'

// --- Log Analytics Workspace (free tier, 5GB/month) ---
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// --- Application Insights (free up to 5GB/month) ---
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
    RetentionInDays: 30
  }
}

// --- App Service Plan (B1 — cheapest production tier) ---
resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  kind: 'linux'
  sku: {
    name: 'B1'
    tier: 'Basic'
  }
  properties: {
    reserved: true // Required for Linux
  }
}

// --- Web App (Node 20 LTS) ---
resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: webAppName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'NODE|20-lts'
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      alwaysOn: true
      appCommandLine: 'npm start'
      appSettings: [
        { name: 'NODE_ENV', value: nodeEnv }
        { name: 'APPLICATIONINSIGHTS_CONNECTION_STRING', value: appInsights.properties.ConnectionString }
        { name: 'WEBSITE_NODE_DEFAULT_VERSION', value: '~20' }
        { name: 'SCM_DO_BUILD_DURING_DEPLOYMENT', value: 'false' }
      ]
      healthCheckPath: '/'
    }
  }
  tags: {
    Environment: environment
    Project: appName
    ManagedBy: 'github-actions'
  }
}

// --- Outputs ---
output webAppName string = webApp.name
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output appInsightsName string = appInsights.name
output resourceGroupName string = resourceGroup().name
