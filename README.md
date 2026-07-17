# skills

<!-- skills:index:start -->
## Included skills (3)

- [`databricks-docs`](./databricks-docs/SKILL.md) - Databricks documentation reference via llms.txt index. Use when other skills do not cover a topic, looking up unfamiliar Databricks features, or needing authoritative docs on APIs, configurations, or platform capabilities.
- [`openwiki`](./openwiki/SKILL.md) - Generate and maintain repository documentation for humans and coding agents under openwiki/. Use when asked to initialize wiki docs, update existing openwiki documentation, document a codebase, create agent instructions from a repo, refresh docs after code changes, or run OpenWiki init/update/chat workflows.
- [`validate-plan`](./validate-plan/SKILL.md) - Adversarially validate plans, specs, RFCs, architecture proposals, migration designs, and other design documents. Use when asked to stress-test assumptions, verify a plan against official docs or code evidence, identify design risks, or produce concrete plan changes that increase robustness.

<!-- skills:index:end -->

A collection of portable [Agent Skills](https://agentskills.io) for any harness.

[![skills.sh](https://skills.sh/b/jope35/skills)](https://skills.sh/jope35/skills)

## Install

```bash
# Install OpenWiki to your agent(s)
npx skills add jope35/skills --skill openwiki

# Install Validate Plan to your agent(s)
npx skills add jope35/skills --skill validate-plan

# Install Databricks Docs to your agent(s)
npx skills add jope35/skills --skill databricks-docs

# List available skills in this repo
npx skills add jope35/skills --list

# Use without installing (pipe to your agent)
npx skills use jope35/skills --skill openwiki
npx skills use jope35/skills --skill validate-plan
npx skills use jope35/skills --skill databricks-docs
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

## Databricks Docs

[`databricks-docs/SKILL.md`](./databricks-docs/SKILL.md) — Databricks documentation reference via the official `llms.txt` index.

Vendored from [`databricks-solutions/ai-dev-kit`](https://github.com/databricks-solutions/ai-dev-kit/tree/main/databricks-skills/databricks-docs). Source metadata is recorded in [`databricks-docs/.source.json`](./databricks-docs/.source.json).

## External skill sync

External skills are direct-vendored into this repo so installers see ordinary skill directories. To add or update external skills:

1. Add an entry to [`external-skills.json`](./external-skills.json):

   ```json
   {
     "name": "skill-name",
     "repo": "https://github.com/org/repo.git",
     "ref": "main",
     "sourcePath": "path/to/skill",
     "targetPath": "skill-name"
   }
   ```

2. Run:

   ```bash
   uv run --locked scripts/sync-external-skills.py
   ```

The sync script copies each listed skill, writes `.source.json` with the upstream commit, and refreshes the generated `Included skills` count at the top of this README.

GitHub Actions also runs this sync on a schedule every 11 hours and opens an automated pull request when vendored skills change.

**Layout (Agent Skills spec):**

```
databricks-docs/
└── SKILL.md
openwiki/
├── SKILL.md
├── LICENSE             # MIT, aligned with upstream openwiki
├── assets/           # OKF/quickstart templates and metadata schema
├── references/       # Detailed mode and edge-case docs
└── scripts/          # Git context + content snapshot helpers
validate-plan/
└── SKILL.md
external-skills.json  # External vendoring manifest
scripts/
└── sync-external-skills.py
```

OpenWiki helper scripts live in the skill package. Run them from the **installed skill path** with **cwd set to the target repository**:

```bash
cd /path/to/target-repo
bash /path/to/installed-skill/scripts/gather-git-context.sh update
bash /path/to/installed-skill/scripts/snapshot-wiki-content.sh
```
