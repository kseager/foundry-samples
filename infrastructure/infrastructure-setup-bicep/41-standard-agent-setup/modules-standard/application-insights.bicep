/*
Application Insights Module (public)

Connects workspace-based Application Insights to the Foundry account so agents export OpenTelemetry
traces (evaluation reads them back). Either:
  - creates a new Log Analytics workspace + Application Insights component (default), or
  - reuses an existing component when existingApplicationInsightsResourceId is set (nothing is created
    or modified on it; only the Foundry connection is added).
*/

@description('Azure region for the tracing resources (new resources only).')
param location string

@description('Name of the Foundry (AI Services) account to connect Application Insights to.')
param aiAccountName string

@description('Name of the Log Analytics workspace to create (ignored when reusing an existing component).')
param logAnalyticsName string

@description('Name of the Application Insights component to create (ignored when reusing an existing component).')
param appInsightsName string

@description('Optional full ARM resource ID of an existing workspace-based Application Insights component. When set, no Log Analytics workspace or component is created.')
param existingApplicationInsightsResourceId string = ''

var useExisting = !empty(existingApplicationInsightsResourceId)
var existingParts = split(existingApplicationInsightsResourceId, '/')
var targetSubscriptionId = useExisting ? existingParts[2] : subscription().subscriptionId
var targetResourceGroupName = useExisting ? existingParts[4] : resourceGroup().name
var targetAppInsightsName = useExisting ? existingParts[8] : appInsightsName

resource aiAccount 'Microsoft.CognitiveServices/accounts@2025-04-01-preview' existing = {
  name: aiAccountName
  scope: resourceGroup()
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = if (!useExisting) {
  name: logAnalyticsName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource newAppInsights 'Microsoft.Insights/components@2020-02-02' = if (!useExisting) {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Normalized reference to the target component (new or existing).
resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: targetAppInsightsName
  scope: resourceGroup(targetSubscriptionId, targetResourceGroupName)
}

// Foundry account connection (category AppInsights) so the agent exports OTel traces here.
resource connection 'Microsoft.CognitiveServices/accounts/connections@2025-04-01-preview' = {
  name: '${aiAccountName}-appinsights'
  parent: aiAccount
  properties: {
    category: 'AppInsights'
    target: appInsights.id
    authType: 'ApiKey'
    isSharedToAll: true
    credentials: {
      key: appInsights.properties.ConnectionString
    }
    metadata: {
      ApiType: 'Azure'
      ResourceId: appInsights.id
    }
  }
  dependsOn: [
    newAppInsights
  ]
}

@description('Name of the Application Insights component.')
output appInsightsName string = targetAppInsightsName

@description('Subscription ID that contains the Application Insights component.')
output appInsightsSubscriptionId string = targetSubscriptionId

@description('Resource group that contains the Application Insights component.')
output appInsightsResourceGroupName string = targetResourceGroupName

@description('Resource ID of the Application Insights component.')
output appInsightsId string = appInsights.id

@description('Application ID of the Application Insights component (for trace queries).')
output appInsightsAppId string = appInsights.properties.AppId

@description('Resource ID of the Log Analytics workspace backing Application Insights.')
output logAnalyticsId string = appInsights.properties.WorkspaceResourceId
