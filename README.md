# skills

A collection of portable [Agent Skills](https://agentskills.io) for any harness.

[![skills.sh](https://skills.sh/b/jope35/skills)](https://skills.sh/jope35/skills)

## Install

```bash
# Install OpenWiki to your agent(s)
npx skills add jope35/skills --skill openwiki

# List available skills in this repo
npx skills add jope35/skills --list

# Use without installing (pipe to your agent)
npx skills use jope35/skills --skill openwiki
```

Compatible with [skills.sh](https://skills.sh) and 70+ agents (Cursor, Claude Code, Codex, OpenCode, Windsurf, and others).

## OpenWiki

[`openwiki/SKILL.md`](./openwiki/SKILL.md) — Generate and maintain repository documentation for humans and coding agents.

Adapted from [langchain-ai/openwiki](https://github.com/langchain-ai/openwiki). Harness- and model-agnostic.

**Triggers:** initialize wiki docs, update `openwiki/` documentation, document a codebase, create agent instructions from a repo.

**Modes:**
- `init` — build documentation from scratch
- `update` — surgical refresh based on git changes since last run
- `chat` — answer questions without modifying docs unless asked

**Layout (Agent Skills spec):**

```
openwiki/
├── SKILL.md
├── assets/          # Templates and schemas
├── references/      # Detailed mode and edge-case docs
└── scripts/         # Git context helper
```
