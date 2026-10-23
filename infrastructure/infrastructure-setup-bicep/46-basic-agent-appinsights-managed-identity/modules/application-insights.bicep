/*
Application Insights Module (resource only)

Creates (or reuses) a workspace-based Application Insights component. It does not depend on the
Foundry project, so it is provisioned in parallel with the account and project. The project
connection is added afterwards by application-insights-connection.bicep.

  - New component: Log Analytics workspace + Application Insights with DisableLocalAuth=true,
    so only Entra ID (managed identity) ingestion is accepted.
  - Existing component (existingApplicationInsightsResourceId): nothing is created or modified.
    For managed identity ingestion to be enforced, the component should already have
    DisableLocalAuth=true.
*/

@description('Azure region for the tracing resources (new resources only).')
param location string

@description('Name of the Log Analytics workspace to create (ignored when reusing an existing component).')
param logAnalyticsName string

@description('Name of the Application Insights component to create (ignored when reusing an existing component).')
param appInsightsName string

@description('Optional full ARM resource ID of an existing workspace-based Application Insights component.')
param existingApplicationInsightsResourceId string = ''

var useExisting = !empty(existingApplicationInsightsResourceId)
var existingParts = split(existingApplicationInsightsResourceId, '/')
var targetSubscriptionId = useExisting ? existingParts[2] : subscription().subscriptionId
var targetResourceGroupName = useExisting ? existingParts[4] : resourceGroup().name
var targetAppInsightsName = useExisting ? existingParts[8] : appInsightsName

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
    DisableLocalAuth: true
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource existingAppInsights 'Microsoft.Insights/components@2020-02-02' existing = if (useExisting) {
  name: targetAppInsightsName
  scope: resourceGroup(targetSubscriptionId, targetResourceGroupName)
}

var appInsightsId = useExisting ? existingAppInsights.id : newAppInsights.id
var appInsightsAppId = useExisting ? existingAppInsights.properties.AppId : newAppInsights.properties.AppId
var appInsightsConnectionString = useExisting ? existingAppInsights.properties.ConnectionString : newAppInsights.properties.ConnectionString

@description('Name of the Application Insights component.')
output appInsightsName string = targetAppInsightsName

@description('Subscription ID that contains the Application Insights component.')
output appInsightsSubscriptionId string = targetSubscriptionId

@description('Resource group that contains the Application Insights component.')
output appInsightsResourceGroupName string = targetResourceGroupName

@description('Resource ID of the Application Insights component.')
output appInsightsId string = appInsightsId

@description('Application ID of the Application Insights component (for trace queries).')
output appInsightsAppId string = appInsightsAppId

@description('Connection string of the Application Insights component.')
output appInsightsConnectionString string = appInsightsConnectionString
