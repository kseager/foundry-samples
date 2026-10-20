# Prompt Agent with Azure AI Search (RAG)

A prompt agent that answers with **RAG** grounded in an **Azure AI Search** index. [`azure.yaml`](./azure.yaml) declares the search tool and its `azure.ai.connection` sibling (Entra auth, no keys).

## Prerequisites

Requires azd 1.36.0 or later. The manifest pins Agents beta.21, Projects beta.14, and Connections
beta.10.

An existing Azure AI Search resource with an index:

```bash
azd env set AZURE_SEARCH_ENDPOINT https://<your-search>.search.windows.net
azd env set AZURE_SEARCH_INDEX_NAME <your-index-name>
```

The index query mode and identity permissions must also be configured. Follow the
[Azure AI Search tool setup](https://learn.microsoft.com/azure/foundry/agents/how-to/tools/ai-search)
for keyless authentication and index requirements. This sample does not create the Search
service, seed the index, or assign its Search roles.

## Deploy

```bash
azd up
azd ai agent invoke "What does the documentation say about the return policy?"
```

## Microsoft Copilot harness

The Microsoft Copilot harness accepts the `azure_ai_search` tool. To test it, create a separately
named agent service with `harness.type: microsoft_copilot_preview` and omit `toolChoice`; an
explicit `tool_choice` is not supported on that harness.

## Setup limitations

The manifest leaves Search permissions, connection-ID resolution, and query-mode selection to
your environment. If retrieval fails, verify the calling identity's Search roles, use the
connection's full ARM resource ID for `project_connection_id`, and set a query type that matches
the index. For a keyword-only index, use `query_type: simple` on the index entry. Do not assume
the unspecified query mode works with every index.
