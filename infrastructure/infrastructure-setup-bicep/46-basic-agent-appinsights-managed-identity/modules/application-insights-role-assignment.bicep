/*
Application Insights Role Assignment Module (managed identity)

Grants the project managed identity access scoped to the Application Insights component:

  Log Analytics Reader               73c42c96-874c-492b-b04d-ab87d138a893  read traces (Monitor, Traces UI, evaluation)
  Privileged Monitoring Data Reader  dbc9c667-e97f-4491-aee6-90b9cf960190  read GenAI content
  Monitoring Metrics Publisher       3913510d-42f4-4e42-8a64-420c390055eb  write evaluation results

Agent identities (hosted and prompt agents) do not exist at deployment time. Grant them
Monitoring Metrics Publisher after the agent is created with scripts/assign_agent_identity_role.py.
*/

@description('Name of the Application Insights component to grant access on.')
param appInsightsName string

@description('Principal (object) ID of the project managed identity.')
param projectPrincipalId string

@description('Built-in role definition GUIDs to assign to the project managed identity.')
param roleDefinitionGuids array = [
  '73c42c96-874c-492b-b04d-ab87d138a893'
  'dbc9c667-e97f-4491-aee6-90b9cf960190'
  '3913510d-42f4-4e42-8a64-420c390055eb'
]

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
  scope: resourceGroup()
}

resource appInsightsRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for roleGuid in roleDefinitionGuids: {
  scope: appInsights
  name: guid(projectPrincipalId, roleGuid, appInsights.id)
  properties: {
    principalId: projectPrincipalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleGuid)
    principalType: 'ServicePrincipal'
  }
}]
