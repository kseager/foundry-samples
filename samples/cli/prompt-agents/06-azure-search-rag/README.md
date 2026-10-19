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

## Validation boundary

On October 19, 2026, the default plain-agent configuration deployed in Canada Central, but its
first query returned a Search access error. The saved tool retained the short connection name
`aisearch-conn`, and the manifest did not specify a query type.

A diagnostic copy supplied Search roles, the connection's full ARM resource ID, and
`query_type: simple` on the index entry to match a seeded keyword index. Both the plain agent and
a separately named Copilot harness agent then completed real `azure_ai_search_call` operations
and correctly returned the synthetic index's 47-day return period, receipt requirement, and
custom-product exclusion with citations.

This demonstrates tool support in both runtimes, not a successful unmodified end-to-end setup.
The diagnostic changed multiple prerequisites; it does not isolate a single cause of the initial
access error. The connection-ID, identity, and query-mode setup still needs to be made explicit
in the minimal sample. All test resources, including the separately created Search service, were
removed afterward.
