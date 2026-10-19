# Prompt Agent with the Microsoft Copilot harness and a Foundry Toolbox

A Microsoft Copilot harness agent backed by a **Foundry Toolbox**, configured in [`azure.yaml`](./azure.yaml).

The sample creates a toolbox containing built-in web search as part of
`azd deploy`.

Requires azd 1.36.0 or later with the Agents beta.21, Projects beta.14, and Toolboxes beta.11
extensions pinned by the manifest.

## Deploy

```bash
azd up
azd ai agent invoke "Search the web for the latest stable Python release and cite the official Python release page."
```

## Current validation blocker

On October 19, 2026, a clean Canada Central `azd up` created the project, Toolbox, and Copilot
harness agent. However, invocation failed during MCP discovery with HTTP 401.

The `toolbox:` shortcut persisted a generic MCP tool with `require_approval: always` but without
`project_connection_id`. This sample does not yet configure authentication from the Agent to the
Foundry Toolbox endpoint. Deployment success alone is therefore not an end-to-end pass.

See the [Browser Automation sample](../microsoft-copilot-harness/browser-automation-blog-research/)
for an independently tested, explicit authenticated Toolbox MCP connection. Choosing and wiring
that identity model into this minimal sample remains follow-up work.
