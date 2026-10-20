param ai_services string = 'aiServices'
param project_name string = 'project'
param description string = 'some description'
param display_name string = 'project_display_name'
param location string = 'eastus'

param modelName string = 'gpt-4.1'
param modelFormat string = 'OpenAI'
param modelVersion string = '2025-04-14'
param modelSkuName string = 'GlobalStandard'
param modelCapacity int = 30

// Create a short, unique suffix, that will be unique to each resource group
// var uniqueSuffix = substring(uniqueString(resourceGroup().id), 0, 4)
param deploymentTimestamp string = utcNow('yyyyMMddHHmmss')
var uniqueSuffix = substring(uniqueString('${resourceGroup().id}-${deploymentTimestamp}'), 0, 4)
var account_name = toLower('${ai_services}${uniqueSuffix}')

@sys.description('Deploy a Log Analytics workspace + Application Insights, connect them to the Foundry account, and grant the project managed identity read access so agent traces can be viewed and evaluated. Adds resources/cost. Default true.')
param deployApplicationInsights bool = true

@sys.description('Optional full ARM resource ID of an existing workspace-based Application Insights component to connect instead of creating a new one. Ignored when deployApplicationInsights is false. The component is not modified; the deployer needs permission to assign roles on it.')
param existingApplicationInsightsResourceId string = ''

var appInsightsName = toLower('${uniqueSuffix}appinsights')
var appInsightsPassedIn = existingApplicationInsightsResourceId != ''
var appInsightsParts = split(existingApplicationInsightsResourceId, '/')
var appInsightsSubscriptionId = appInsightsPassedIn ? appInsightsParts[2] : subscription().subscriptionId
var appInsightsResourceGroupName = appInsightsPassedIn ? appInsightsParts[4] : resourceGroup().name
var targetAppInsightsName = appInsightsPassedIn ? appInsightsParts[8] : appInsightsName
/*
  Step 1: Create a Cognitive Services Account and deployment an agent compatible model
  
  - Note: Only public networking is supported.
  
*/ 

module aiAccount 'modules/ai-account-keys.bicep' = {
  name: 'ai-${account_name}-${uniqueSuffix}-deployment'
  params: {
    // workspace organization
    account_name: account_name
    location: location

    modelName: modelName
    modelFormat: modelFormat
    modelVersion: modelVersion
    modelSkuName: modelSkuName
    modelCapacity: modelCapacity
  }
}

/*
  Step 2: Create a Cognitive Services Project
  
  - Note: Only public networking is supported.
  
*/
module aiProject 'modules/ai-project-keys.bicep' = {
  name: 'ai-${project_name}-${uniqueSuffix}-deployment'
  params: {
    // workspace organization
    project_name: project_name
    description: description
    display_name: display_name
    location: location

    // dependent resources
    account_name: aiAccount.outputs.account_name
  }
}
module bingConnection 'modules/add-bing-search-tool.bicep' = {
  name: 'ai-${project_name}-${uniqueSuffix}-bing-connection'
  params: {
    // dependent resources
    account_name: aiAccount.outputs.account_name
  }
}

// Application Insights + Foundry connection (agent tracing), gated by deployApplicationInsights
module applicationInsights 'modules/application-insights.bicep' = if (deployApplicationInsights) {
  name: 'app-insights-${uniqueSuffix}-deployment'
  params: {
    location: location
    aiAccountName: aiAccount.outputs.account_name
    logAnalyticsName: toLower('${uniqueSuffix}loganalytics')
    appInsightsName: appInsightsName
    existingApplicationInsightsResourceId: existingApplicationInsightsResourceId
  }
  dependsOn: [
    aiProject
  ]
}

module applicationInsightsRoleAssignment 'modules/application-insights-role-assignment.bicep' = if (deployApplicationInsights) {
  name: 'app-insights-ra-${uniqueSuffix}-deployment'
  scope: resourceGroup(appInsightsSubscriptionId, appInsightsResourceGroupName)
  params: {
    appInsightsName: targetAppInsightsName
    projectPrincipalId: aiProject.outputs.projectPrincipalId
  }
  dependsOn: [
    applicationInsights
  ]
}

output ENDPOINT string = aiAccount.outputs.aiServicesTarget
