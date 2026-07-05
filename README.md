# skills

A collection of portable Cursor agent skills.

## OpenWiki

[`openwiki/SKILL.md`](./openwiki/SKILL.md) — Generate and maintain repository documentation for humans and coding agents.

Adapted from [langchain-ai/openwiki](https://github.com/langchain-ai/openwiki). Works in any Cursor environment without the OpenWiki CLI.

**Triggers:** initialize wiki docs, update existing `openwiki/` documentation, document a codebase, create agent instructions from a repo.

**Modes:**
- `init` — build documentation from scratch
- `update` — surgical refresh based on git changes since last run
- `chat` — answer questions without modifying docs unless asked

**Templates:** `openwiki/templates/` — AGENTS.md section, metadata schema, quickstart skeleton.
