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

## Validated behavior

On October 19, 2026, a clean Canada Central deployment published `travel-guide` version 1 and
attached it to the plain Agent. That Agent returned a travel itinerary, but a follow-up asking for
the skill's exact output sections reported that it could not access the skill content. A saved
skill reference alone is not evidence that the plain runtime loaded it.

A separately named Microsoft Copilot harness variant used the same skill dependency and visibly
called `skill` with `{"skill":"travel-guide"}`. Its completed answer followed all six sections:
Overview, Day-by-day itinerary, Neighborhoods, Food & drink, Practical tips, and Photo-worthy stops.
Use that variant for the demonstrated skill-loading workflow. The test did not change the
plain-agent default in this sample.
