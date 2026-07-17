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

Adapted from the repository/code mode in [langchain-ai/openwiki 0.2.0](https://github.com/langchain-ai/openwiki/tree/0.2.0) at [`d4e94ab`](https://github.com/langchain-ai/openwiki/commit/d4e94ab513ab13908c6b61346b23dc17bbd59b1f). Harness- and model-agnostic. Licensed under [MIT](openwiki/LICENSE), consistent with upstream.

**Triggers:** initialize code wiki docs, update `openwiki/` after repository changes, document a codebase, answer from an existing repository wiki, migrate wiki pages to OKF.

**Modes:**
- `init` — build documentation from scratch
- `update` — surgical refresh based on git changes since last run
- `chat` — answer questions without modifying docs unless asked

The skill captures OpenWiki 0.2's portable code-mode contracts: `openwiki/INSTRUCTIONS.md` is a preserved user brief, generated pages use OKF front matter and semantic links, `index.md` is not hand-edited, and normal wiki runs do not modify `AGENTS.md` or `CLAUDE.md`.

## Validate Plan

[`validate-plan/SKILL.md`](./validate-plan/SKILL.md) — Adversarially validate plans, specs, RFCs, and design documents, then return small, meaningful changes that improve robustness.

**Triggers:** validate a plan, stress-test a spec, challenge design assumptions, de-risk an RFC, verify architecture or rollout assumptions against code and official docs.

**Evidence sources:** local source/docs, Exa, Context7, Ref, official documentation, standards, and `llms.txt` documentation indexes where available. Blocked or unavailable evidence checks are flagged instead of silently skipped.

**Output:** concrete plan edits, including a verification/validation section that explains how to test the plan's output.

**Layout (Agent Skills spec):**

```
openwiki/
├── SKILL.md
├── LICENSE             # MIT, aligned with upstream openwiki
├── assets/           # OKF/quickstart templates and metadata schema
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
