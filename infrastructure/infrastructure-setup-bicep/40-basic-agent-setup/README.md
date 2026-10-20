# Azure AI Foundry Agent Service: Basic Setup 

## Basic Agent Setup
   

This bicep template provisions required resources for a basic project setup. A new Cognitive Services Account is created, a gpt-4o model is deployed, and a new project is created.

All agents created in this project will automatically use Microsoft managed, multitenant search and storage resources.

### Prerequisites
1. To deploy the template, you must have the following roles:
    * **Foundry Account Owner** or **Contributor** 
1. To create your first agent you must have the permissions:
    * **Foundry User**

For more information, [see the getting started guide.](https://learn.microsoft.com/en-us/azure/ai-services/agents/environment-setup)
 
### Steps

1. To deploy this template, click the "Deploy to Azure" button or you can run one of the following commands:

[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fazure-ai-foundry%2Ffoundry-samples%2Frefs%2Fheads%2Fmain%2Finfrastructure%2Finfrastructure-setup-bicep%2F40-basic-agent-setup%2Fazuredeploy.json)


* Create new (or use existing) resource group:

```bash
    az group create --name <new-rg-name> --location eastus
```

* Deploy the template

```bash
    az deployment group create --resource-group <new-rg-name> --template-file main.bicep
```

## Agent tracing & evaluation (Application Insights)

By default (`deployApplicationInsights = true`) this template also:

- Deploys a **Log Analytics workspace** and a **workspace-based Application Insights** component and connects it to the Foundry account, so agents export OpenTelemetry traces.
- Grants the **project managed identity** **Log Analytics Reader** and **Privileged Monitoring Data Reader** on the component so evaluation can read traces, including GenAI prompt/response content.

This adds Log Analytics / Application Insights cost. Options:

| Parameter | Default | Effect |
|---|---|---|
| `deployApplicationInsights` | `true` | `false` skips all tracing resources and RBAC. |
| `existingApplicationInsightsResourceId` | `''` | Full resource ID of an existing **workspace-based** Application Insights component. No Log Analytics / component is created and the existing component is not modified; only the Foundry connection and project roles are added. The deployer needs permission to assign roles on it (e.g. Owner or User Access Administrator). |

```bash
# Use an existing Application Insights
az deployment group create --resource-group <rg> --template-file main.bicep \
  --parameters existingApplicationInsightsResourceId=/subscriptions/<sub>/resourceGroups/<rg>/providers/microsoft.insights/components/<name>

# Skip Application Insights
az deployment group create --resource-group <rg> --template-file main.bicep --parameters deployApplicationInsights=false
```

To add tracing to an existing Foundry resource instead, see [01-connections/connection-application-insights.bicep](../01-connections/connection-application-insights.bicep).
