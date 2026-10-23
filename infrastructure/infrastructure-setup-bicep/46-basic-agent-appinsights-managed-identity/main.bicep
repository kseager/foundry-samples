// Basic agent setup with managed identity Application Insights tracing (hosted agent ready)
@description('The name of the Azure AI Foundry resource.')
@maxLength(9)
param aiServicesName string = 'foundy'

@description('The name of your project')
param projectName string = 'project'

@description('The description of your project')
param projectDescription string = 'Project with managed identity Application Insights tracing'

@description('The display name of your project')
param projectDisplayName string = 'project_display_name'

// Short unique suffix per resource group deployment
param deploymentTimestamp string = utcNow('yyyyMMddHHmmss')
var uniqueSuffix = substring(uniqueString('${resourceGroup().id}-${deploymentTimestamp}'), 0, 4)
var accountName = toLower('${aiServicesName}${uniqueSuffix}')

@description('Deploy Log Analytics + Application Insights (DisableLocalAuth=true), link them to the project with a ProjectManagedIdentity connection, and grant the project managed identity access. Set false to deploy without tracing resources. Default true.')
param deployApplicationInsights bool = true

@description('Optional full ARM resource ID of an existing workspace-based Application Insights component to link instead of creating a new one. Ignored when deployApplicationInsights is false. The component is not modified; the deployer needs permission to assign roles on it.')
param existingApplicationInsightsResourceId string = ''

@description('Assign the roles on Application Insights (project managed identity: Monitoring Metrics Publisher; optional user: Log Analytics Reader). Set false only to test the connection-only experience. Default true.')
param assignProjectMonitoringRoles bool = true

@description('Object ID of the user who views traces; granted Log Analytics Reader on Application Insights. Get yours with: az ad signed-in-user show --query id -o tsv. Leave empty to skip.')
param userPrincipalId string = ''
var appInsightsName = toLower('${uniqueSuffix}appinsights')
var appInsightsPassedIn = existingApplicationInsightsResourceId != ''
var appInsightsParts = split(existingApplicationInsightsResourceId, '/')
var appInsightsSubscriptionId = appInsightsPassedIn ? appInsightsParts[2] : subscription().subscriptionId
var appInsightsResourceGroupName = appInsightsPassedIn ? appInsightsParts[4] : resourceGroup().name
var targetAppInsightsName = appInsightsPassedIn ? appInsightsParts[8] : appInsightsName

@allowed([
  'australiaeast'
  'canadaeast'
  'eastus'
  'eastus2'
  'francecentral'
  'japaneast'
  'koreacentral'
  'norwayeast'
  'polandcentral'
  'southindia'
  'swedencentral'
  'switzerlandnorth'
  'uaenorth'
  'uksouth'
  'westus'
  'westus2'
  'westus3'
  'westeurope'
  'southeastasia'
  'brazilsouth'
  'germanywestcentral'
  'italynorth'
  'southafricanorth'
  'southcentralus'
])
@description('The Azure region where your AI Foundry resource and project will be created.')
param location string = 'eastus2'

@description('The name of the OpenAI model you want to deploy')
param modelName string = 'gpt-4.1'

@description('The model format of the model you want to deploy. Example: OpenAI')
param modelFormat string = 'OpenAI'

@description('The version of the model you want to deploy. Example: 2024-11-20')
param modelVersion string = '2025-04-14'

@description('The SKU name for the model deployment. Example: GlobalStandard')
param modelSkuName string = 'GlobalStandard'

@description('The capacity of the model deployment in TPM.')
param modelCapacity int = 40

resource account 'Microsoft.CognitiveServices/accounts@2025-04-01-preview' = {
  name: accountName
  location: location
  sku: {
    name: 'S0'
  }
  kind: 'AIServices'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    allowProjectManagement: true
    customSubDomainName: toLower(accountName)
    networkAcls: {
      defaultAction: 'Allow'
      virtualNetworkRules: []
      ipRules: []
    }
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: true
  }
}

resource project 'Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview' = {
  parent: account
  name: projectName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    description: projectDescription
    displayName: projectDisplayName
  }
}

resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: account
  name: modelName
  sku: {
    capacity: modelCapacity
    name: modelSkuName
  }
  properties: {
    model: {
      name: modelName
      format: modelFormat
      version: modelVersion
    }
  }
}

// Provisioned in parallel with the account and project (no dependency on them)
module applicationInsights 'modules/application-insights.bicep' = if (deployApplicationInsights) {
  name: 'app-insights-${uniqueSuffix}-deployment'
  params: {
    location: location
    logAnalyticsName: toLower('${uniqueSuffix}loganalytics')
    appInsightsName: appInsightsName
    existingApplicationInsightsResourceId: existingApplicationInsightsResourceId
  }
}

// Link Application Insights to the project once both exist
module applicationInsightsConnection 'modules/application-insights-connection.bicep' = if (deployApplicationInsights) {
  name: 'app-insights-connection-${uniqueSuffix}-deployment'
  params: {
    aiAccountName: account.name
    projectName: project.name
    appInsightsId: applicationInsights!.outputs.appInsightsId
    appInsightsConnectionString: applicationInsights!.outputs.appInsightsConnectionString
  }
}

// Project managed identity (write) and viewing user (read) roles, scoped to Application Insights
module applicationInsightsRoleAssignment 'modules/application-insights-role-assignment.bicep' = if (deployApplicationInsights && assignProjectMonitoringRoles) {
  name: 'app-insights-ra-${uniqueSuffix}-deployment'
  scope: resourceGroup(appInsightsSubscriptionId, appInsightsResourceGroupName)
  params: {
    appInsightsName: targetAppInsightsName
    projectPrincipalId: project.identity.principalId
    userPrincipalId: userPrincipalId
  }
  dependsOn: [
    applicationInsights
  ]
}

output accountName string = account.name
output projectName string = project.name
output accountEndpoint string = account.properties.endpoint
output projectEndpoint string = 'https://${account.name}.services.ai.azure.com/api/projects/${project.name}'
output projectPrincipalId string = project.identity.principalId
output applicationInsightsResourceId string = deployApplicationInsights ? applicationInsights!.outputs.appInsightsId : ''
output applicationInsightsAppId string = deployApplicationInsights ? applicationInsights!.outputs.appInsightsAppId : ''
