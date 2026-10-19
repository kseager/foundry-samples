# Basic Prompt Agent

The minimal prompt agent: a model plus inline instructions, defined in [`azure.yaml`](./azure.yaml). No tools or skills.

Requires azd 1.36.0 or later. The manifest pins Agents beta.21 and Projects beta.14.

## Deploy

```bash
azd up
azd ai agent invoke "Hi"
```

## Microsoft Copilot harness

To use the Microsoft Copilot harness, add this block to the agent service in [`azure.yaml`](./azure.yaml):

```yaml
harness:
  type: microsoft_copilot_preview
```

Create a separate agent name when testing both variants in the same project.

## Validated result

On October 19, 2026, a clean Canada Central deployment passed using the pinned extensions.
The default plain agent and a separately named Copilot harness variant both returned `391`
for `17 * 23`. The isolated test environment was deleted and purged afterward.
