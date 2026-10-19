# Prompt Agent with MCP Tools

A prompt agent that calls the public **Microsoft Learn** [MCP](https://modelcontextprotocol.io/) server without authentication. The tool is configured for unattended use in [`azure.yaml`](./azure.yaml).

Requires azd 1.36.0 or later. The manifest pins Agents beta.21 and Projects beta.14.

## Deploy

```bash
azd up
azd ai agent invoke "How do I create a hosted agent with azd? Cite the Microsoft Learn docs."
```

## Microsoft Copilot harness

To use the Microsoft Copilot harness, add this block to a separately named agent service in [`azure.yaml`](./azure.yaml):

```yaml
harness:
  type: microsoft_copilot_preview
```

## Validation boundary

On October 19, 2026, the plain sample and a separately named Copilot harness variant deployed
in Canada Central. The Copilot response contained a successful
`microsoft_docs_search` MCP call, but a subsequent model continuation hit `rate_limit_exceeded`.
The plain invocation also throttled, including through the documented CLI command.

The default 10-capacity-unit deployment was not sufficient for this test. Increasing only the
disposable deployment's allocation did not produce a complete successful answer during the test
window, so no minimum sufficient quota or end-to-end pass is claimed. Investigate the rate-limit
response before treating tool-call success as a completed research result.
