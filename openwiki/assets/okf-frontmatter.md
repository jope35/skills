# OKF front matter

Every Markdown page OpenWiki creates or substantively updates, including temporary `_plan.md`, begins with this YAML shape:

```yaml
---
type: <short, self-explanatory concept kind>
title: <human-readable display name>
description: <one or two sentences optimized for search and retrieval>
resource: <optional canonical URI or source path>
tags: [<tag>, <tag>]
---
```

Rules:

- `type`, `title`, `description`, and `tags` are required.
- `resource` is optional and should be omitted when there is no canonical asset.
- Use only these fields.
- Write valid YAML values with no placeholders or explanatory comments.
- Keep `description` specific enough for retrieval without repeating the page body.
- Use a short concept kind that describes the page, such as `Repository Guide`, `Architecture`, `Workflow`, `Domain Concept`, `API Endpoint`, `Data Model`, `Runbook`, or `Reference`. Type values are not a fixed enum.

Example:

```yaml
---
type: Workflow
title: Documentation update workflow
description: Explains how repository changes are mapped to surgical OpenWiki page updates and no-op decisions.
resource: src/agent/prompt.ts
tags: [openwiki, documentation, maintenance]
---
```
