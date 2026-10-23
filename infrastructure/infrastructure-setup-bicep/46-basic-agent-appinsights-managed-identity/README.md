# 46 - Basic agent setup with managed identity Application Insights tracing (hosted agent)

Creates a Foundry account, project and model deployment, plus a workspace-based Application Insights
component that the project links to with **Microsoft Entra ID (project managed identity)** - no
instrumentation key is stored. A companion `agent/` and `scripts/` folder shows a hosted agent writing
traces and verifies the interaction is retrievable.

## What the template deploys (control plane)

| Resource | Notes |
|---|---|
| Foundry account + project + `gpt-4.1` deployment | Basic agent setup, platform-managed agent state |
| Log Analytics + Application Insights | `DisableLocalAuth=true`, provisioned in parallel with the account and project |
| Project connection | `category: AppInsights`, `authType: ProjectManagedIdentity`, connection string in metadata |
| Roles on Application Insights for the project managed identity | Log Analytics Reader, Privileged Monitoring Data Reader, Monitoring Metrics Publisher |

### Parameters

| Parameter | Default | Description |
|---|---|---|
| `deployApplicationInsights` | `true` | Set `false` to deploy without any tracing resources |
| `existingApplicationInsightsResourceId` | `''` | Link an existing workspace-based component instead of creating one. It is not modified; the deployer needs permission to assign roles on it. For managed identity ingestion to be enforced, set `DisableLocalAuth=true` on it |
| `location` | `eastus2` | Region |

The deployer needs `Microsoft.Authorization/roleAssignments/write` on the Application Insights component (for example Owner or User Access Administrator).

## Hosted agent identity (data plane, after deployment)

Agent identities do not exist when the template runs, so Bicep cannot grant them access. After the hosted
agent is created, assign its identity **Monitoring Metrics Publisher** on the component:

```bash
python scripts/assign_agent_identity_role.py --app-insights-id <applicationInsightsResourceId> --principal-id <agent identity object id>
```

## Run end to end

1. Deploy:
   ```bash
   az group create -n <rg> -l eastus2
   az deployment group create -g <rg> -f main.bicep
   ```
   Outputs include `projectEndpoint`, `applicationInsightsResourceId` and `applicationInsightsAppId`.
2. Deploy the hosted agent in `agent/` with `azd` 1.27.1+ and the `azure.ai.agents` extension. Set `FOUNDRY_PROJECT_ENDPOINT` and `FOUNDRY_PROJECT_ID` in the azd environment to the existing project (`azd env set ...`), then run `azd deploy` from `agent/`. `azd ai agent show <agent>` prints the agent's `Instance Identity Principal ID`.
3. Grant the agent identity the role (above), passing that principal id to `scripts/assign_agent_identity_role.py`.
4. Verify:
   ```bash
   pip install requests azure-identity
   python scripts/verify_traces.py --project-endpoint <projectEndpoint> --agent-name <agent> --app-id <applicationInsightsAppId>
   ```
   The script invokes the agent with a unique marker and polls Application Insights (`dependencies` table, `gen_ai.*` dimensions) until spans containing that marker in `gen_ai.input.messages` appear. Ingestion usually takes a few minutes.

## Tested

Deployed to westus3 (eastus2 had no account quota): connection `ProjectManagedIdentity`, three roles on the component, `DisableLocalAuth=true`. The hosted agent deployed with azd, and an invocation produced `invoke_agent` and `chat` spans in `dependencies`, found by `verify_traces.py`. Spans also appeared in a run made before the agent identity role was assigned, so the platform's own span export did not depend on that role in this test. The agent's own telemetry (`traces`, `requests`) also lands in the component.

### Bring-your-own Application Insights (hosted agent, observed)

Tested with `existingApplicationInsightsResourceId` pointing at a component in another project's resource group, and the project managed identity holding **no** roles on it (`assignProjectMonitoringRoles=false` in the test bed). Platform spans (`invoke_agent`, `chat`, cloud role `responsesapi`) were checked in the `dependencies` table after waiting 10 minutes or more.

| Roles on the component | Platform spans |
|---|---|
| None | Not seen (the agent's own `traces` and `exceptions` still arrive) |
| Agent identity only: Monitoring Metrics Publisher | Not seen |
| Agent identity and project managed identity: Monitoring Metrics Publisher | Seen |

Project-managed-identity-only was not tested, so which of the two identities gates the platform spans is not isolated. Prompt agents produced no telemetry with no roles and with the agent identity role. The Traces page in the Foundry portal loaded for the signed-in user with the project managed identity holding no roles, which is consistent with the portal querying as the user. Read-side role requirements for the project managed identity were not tested.

## Notes

- Bicep, CLI and REST connection creation did not add any role assignment on the component in this test; every role write in the Activity Log was made by the deployer.
- Agent name and id are not unique across projects. Two projects sharing one component produce spans with the same `agent name` and `agent id`; only `microsoft.foundry.project.id` tells them apart, so filter on it in queries.

- If Application Insights creation fails the deployment fails; a rerun reuses what exists. Bicep cannot offer a "warn and continue" path; wrap the deployment in a script if you need that.
- Delete the resource group to clean up.
