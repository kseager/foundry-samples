# Prompt Agent with Skills

A prompt agent backed by a reusable, file-based **skill**. [`azure.yaml`](./azure.yaml) declares the `azure.ai.skill` sibling and the agent dependency; the bundle lives under [`skills/`](./skills/).

Requires azd 1.36.0 or later. The manifest pins Agents beta.21, Projects beta.14, and Skills beta.8.

## Deploy

```bash
azd up
azd ai agent invoke "Make me a 3-day travel guide for Lisbon focused on food and viewpoints."
```

## Microsoft Copilot harness

To use the Microsoft Copilot harness, add this block to a separately named agent service in [`azure.yaml`](./azure.yaml):

```yaml
harness:
  type: microsoft_copilot_preview
```

## Known limitation

The default plain Agent can generate an itinerary without loading the attached skill. For runtime
skill loading, select the Copilot harness as described above and inspect the response for a
`skill` call. A saved skill reference or plausible itinerary alone does not confirm skill use.
