# skills

A collection of portable [Agent Skills](https://agentskills.io) for any harness.

[![skills.sh](https://skills.sh/b/jope35/skills)](https://skills.sh/jope35/skills)

## Install

```bash
# Install OpenWiki to your agent(s)
npx skills add jope35/skills --skill openwiki

# Install Validate Plan to your agent(s)
npx skills add jope35/skills --skill validate-plan

# List available skills in this repo
npx skills add jope35/skills --list

# Use without installing (pipe to your agent)
npx skills use jope35/skills --skill openwiki
npx skills use jope35/skills --skill validate-plan
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

## Validate Plan

[`validate-plan/SKILL.md`](./validate-plan/SKILL.md) — Adversarially validate plans, specs, RFCs, and design documents, then return small, meaningful changes that improve robustness.

**Triggers:** validate a plan, stress-test a spec, challenge design assumptions, de-risk an RFC, verify architecture or rollout assumptions against code and official docs.

**Evidence sources:** local source/docs, Exa, Context7, Ref, official documentation, standards, and `llms.txt` documentation indexes where available.

**Output:** concrete plan edits, including a verification/validation section that explains how to test the plan's output.

**Layout (Agent Skills spec):**

```
openwiki/
├── SKILL.md
├── assets/           # Templates and schemas
├── references/       # Detailed mode and edge-case docs
└── scripts/          # Git context + content snapshot helpers
validate-plan/
└── SKILL.md
```

OpenWiki helper scripts live in the skill package. Run them from the **installed skill path** with **cwd set to the target repository**:

```bash
cd /path/to/target-repo
bash /path/to/installed-skill/scripts/gather-git-context.sh update
bash /path/to/installed-skill/scripts/snapshot-wiki-content.sh
```
