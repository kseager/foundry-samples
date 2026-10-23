/*
Application Insights Connection Module (managed identity)

Adds the project-level Foundry connection (category AppInsights, authType ProjectManagedIdentity).
No key is stored; the project managed identity authenticates with the role assignments granted
by application-insights-role-assignment.bicep. Deployed only after both the project and the
Application Insights component exist.
*/

@description('Name of the Foundry (AI Services) account that owns the project.')
param aiAccountName string

@description('Name of the Foundry project to connect Application Insights to.')
param projectName string

@description('Resource ID of the Application Insights component.')
param appInsightsId string

@description('Connection string of the Application Insights component (not a secret on its own with local auth disabled).')
param appInsightsConnectionString string

resource aiAccount 'Microsoft.CognitiveServices/accounts@2025-04-01-preview' existing = {
  name: aiAccountName
}

resource project 'Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview' existing = {
  name: projectName
  parent: aiAccount
}

resource connection 'Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview' = {
  name: '${projectName}-appinsights'
  parent: project
  properties: {
    category: 'AppInsights'
    target: appInsightsId
    authType: 'ProjectManagedIdentity'
    metadata: {
      ApiType: 'Azure'
      ResourceId: appInsightsId
      ApplicationInsightsConnectionString: appInsightsConnectionString
    }
  }
}

output connectionName string = connection.name
