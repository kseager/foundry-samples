# Azure AI Foundry Agent Service: Basic Agent Setup with the Bing Search Tool

Use this template as a starting point for creating a basic agent project where you know you will want to create agents with the Grounding with Bing Search tool. For more information, see [Azure AI Services Agents Environment Setup](https://learn.microsoft.com/en-us/azure/ai-services/agents/environment-setup).

> **Note:** Deploying the template does not create an agent; it only provisions the necessary resources to get started.


## Getting started

Creating your first agent with Azure AI Foundry Agent Service is a two-step process:

1. **Set up your agent environment.**
2. **Create and configure your agent** using either your preferred SDK or the Azure Foundry Portal.


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
