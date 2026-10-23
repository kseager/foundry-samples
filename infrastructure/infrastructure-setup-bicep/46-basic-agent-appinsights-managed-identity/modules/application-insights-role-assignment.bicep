/*
Application Insights Role Assignment Module (managed identity)

Scoped to the Application Insights component:

  Project managed identity: Monitoring Metrics Publisher  3913510d-42f4-4e42-8a64-420c390055eb  write telemetry
  Deploying user:           Log Analytics Reader          73c42c96-874c-492b-b04d-ab87d138a893  view traces (the portal queries as the user)

Agent identities (hosted and prompt agents) do not exist at deployment time. The platform
`invoke_agent` and `chat` spans were observed with only the project MI holding
Monitoring Metrics Publisher. Agent-specific telemetry requirements are not fully tested.
*/

@description('Name of the Application Insights component to grant access on.')
param appInsightsName string

@description('Principal (object) ID of the project managed identity.')
param projectPrincipalId string

@description('Object ID of the user who will view traces. Leave empty to skip the user grant.')
param userPrincipalId string = ''

var metricsPublisherRoleGuid = '3913510d-42f4-4e42-8a64-420c390055eb'
var logAnalyticsReaderRoleGuid = '73c42c96-874c-492b-b04d-ab87d138a893'

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
  scope: resourceGroup()
}

resource projectMetricsPublisher 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: appInsights
  name: guid(projectPrincipalId, metricsPublisherRoleGuid, appInsights.id)
  properties: {
    principalId: projectPrincipalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', metricsPublisherRoleGuid)
    principalType: 'ServicePrincipal'
  }
}

resource userLogAnalyticsReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(userPrincipalId)) {
  scope: appInsights
  name: guid(userPrincipalId, logAnalyticsReaderRoleGuid, appInsights.id)
  properties: {
    principalId: userPrincipalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', logAnalyticsReaderRoleGuid)
    principalType: 'User'
  }
}
