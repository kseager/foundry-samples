# Prompt Agent with Function Tools

A prompt agent that declares **client-executed function tools** (`get_weather`, `convert_currency`) in [`azure.yaml`](./azure.yaml). `type: function` declares the schema only; the model emits a tool call and your application executes it and returns the result.

Requires azd 1.36.0 or later. The manifest pins Agents beta.21 and Projects beta.14.

## Deploy

```bash
azd up
azd ai agent invoke "What is the weather in Seattle in celsius?"
```

This sample does not include the application-side function implementations. An invocation can
return a function request without a text answer; the CLI does not fetch live weather or execute
currency conversion for you. Inspect the Responses output and implement the function-result
round trip in your client.

## Microsoft Copilot harness

To test non-strict function tools with the Microsoft Copilot harness, add this block to a separately named agent service in [`azure.yaml`](./azure.yaml):

```yaml
harness:
  type: microsoft_copilot_preview
```

Also set `strict: false` on each function tool. Strict function mode is not supported by the Copilot harness.
Remove `toolChoice: auto` from that agent service as well; the Copilot harness rejects
an explicit `tool_choice` setting.

## Known limitations

Use foreground Responses requests for client-executed function tools. Background Copilot requests
can complete without returning the function call.

The 10-capacity-unit model deployment can throttle repeated requests. A rate-limit failure does not
mean the function schema is invalid.
