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

## Known limitation

The `toolbox:` shortcut adds an MCP endpoint without a `project_connection_id` to supply
authentication. Invocation can fail during MCP discovery with HTTP 401 even when deployment
succeeds. This sample does not yet configure authentication from the Agent to the Foundry Toolbox.

See the [Browser Automation sample](../microsoft-copilot-harness/browser-automation-blog-research/)
for an explicit authenticated Toolbox MCP connection.
