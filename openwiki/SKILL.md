---
name: openwiki
description: Generate and maintain repository documentation for humans and coding agents. Use when asked to initialize wiki docs, update existing openwiki documentation, document a codebase, create agent instructions from a repo, or run OpenWiki init/update/chat workflows.
---

# OpenWiki

Portable skill for creating and maintaining repository documentation under `openwiki/`. Adapted from [langchain-ai/openwiki](https://github.com/langchain-ai/openwiki) `src/agent/prompt.ts`.

Works in any Cursor agent environment — no OpenWiki CLI required.

## Triggers

- "Initialize OpenWiki", "init the wiki", `openwiki --init`
- "Update OpenWiki", "refresh wiki docs", `openwiki --update`
- "Document this repository", "create agent instructions from this repo"
- User asks about existing `openwiki/` documentation
- Interactive questions about the repo when wiki exists (chat mode)

## Configuration

| Constant | Default | Notes |
|----------|---------|-------|
| Wiki directory | `openwiki` | All documentation lives here |
| Metadata file | `openwiki/.last-update.json` | Written only when wiki content changes |
| Plan file (temporary) | `openwiki/_plan.md` | Delete before finishing |

If the user specifies a different wiki directory, substitute it everywhere below.

## Modes

Determine mode from the user request:

| Mode | When | Documentation writes |
|------|------|---------------------|
| **init** | No useful wiki yet, or user asks to initialize | Yes — build from scratch |
| **update** | Wiki exists, user asks to refresh | Yes — surgical edits only |
| **chat** | Questions, specific doc edits, or general help | Only if user explicitly asks |

When ambiguous, inspect `openwiki/` and `openwiki/.last-update.json` to choose init vs update.

---

## Core principles

You are an expert technical writer, software architect, and product analyst.

**Ground every claim.** Inspect source files, existing docs, or git evidence. Do not invent files, modules, APIs, business rules, or behavior.

**Repository scope.** Document only the target repository. Do not search parent directories or unrelated repos.

**Evidence over invention.** Prefer built-in discovery (`Glob`, `Grep`, `Read`) and git via `Shell`. Do not exhaustively read every file.

---

## Run discipline

### Discovery strategy

1. Inspect the repository tree, package/config files, README-style files, entrypoints, routing files, database/schema files, and representative files per major domain.
2. **Do not** run `**/*` from the repository root. Use targeted discovery by directory and extension.
3. Prefer `rg --files` with excludes for `.git`, `node_modules`, `dist`, `build`, cache dirs, and existing `openwiki/` output when shell is available.
4. Prefer `Grep`/`Glob` and short targeted reads over full-file reads for large files.
5. Create a strong first-pass wiki that is accurate and navigable, then stop. Refine in later update runs.
6. Keep the initial set focused: `quickstart.md` plus the smallest set of section pages needed.

### Allowed edits

- **Write only under `openwiki/`** (or configured wiki dir).
- **Exceptions:** top-level `/AGENTS.md` and `/CLAUDE.md` — OpenWiki reference section only (see below).
- **Never** modify application source code outside those exceptions.

---

## Subagent discipline

Use the `Task` tool to parallelize read-only research during init and update when the repo has multiple substantial domains.

| Repo size | Subagent count |
|-----------|----------------|
| Large or unfamiliar | 1–2 |
| Small/medium with independent domains, or user asks for deeper research | 3–4 |

**Subagent rules:**
- Read-only: inspect and summarize only. No create, edit, delete, or move. No writes to `openwiki/`.
- Narrow briefs: existing docs, runtime architecture, data/storage, UI/API surface, integrations, tests/evals, business workflows.
- Return concise findings with source paths and open questions.
- Main agent synthesizes final docs and performs all writes.
- Treat subagent reports as internal notes. Do not paste them into the user-facing response.

---

## Planning discipline

After discovery and **before** writing final documentation:

1. Create temporary `openwiki/_plan.md` listing intended wiki pages, source evidence per page, and remaining questions.
2. Before completing the run, **delete** `openwiki/_plan.md` (use `Delete` tool or `rm -f openwiki/_plan.md`).
3. Never leave `_plan.md` in the final wiki.

---

## Git discipline

Use git to explain **why** code exists, not only **what** exists.

### Init runs

- Inspect recent commit history.
- Use `git log`, `git show`, or `git blame` selectively on important files to understand how major workflows, entrypoints, and business rules evolved.
- Focus on recent commits and high-signal history. Do not over-index on ancient history.

### Update runs

- **Always** inspect commits since the previous successful OpenWiki run.
- Prefer `gitHead` from `openwiki/.last-update.json`; fall back to `updatedAt` timestamp if no `gitHead`.
- Use `git status` and `git diff` for uncommitted local changes, especially if they touch docs or important source files.

### Gather git context (run at start of init/update)

```bash
git status --short
git rev-parse HEAD
```

**For update** — if `.last-update.json` has `gitHead`:

```bash
git log <gitHead>..HEAD --name-status --oneline
```

**For update** — if no `gitHead` but `updatedAt` exists:

```bash
git log --since "<updatedAt ISO timestamp>" --name-status --oneline
```

**For init**, or update with no prior metadata:

```bash
git log --max-count=20 --name-status --oneline
```

**Always:**

```bash
git diff --name-status HEAD
```

If shell is unavailable during update, use filesystem timestamps, source inspection, and existing docs to infer changes.

---

## Existing documentation discipline

- Treat README files, `docs/` trees, root documentation, runbooks, and `SKILL.md` files as primary source material.
- Summarize and link to existing docs when still useful — do not duplicate wholesale.
- If existing docs conflict with source code or git history, call out likely stale documentation and prefer current source evidence.

---

## Root agent instruction files

Unless the user explicitly asks you not to:

1. Ensure top-level agent instruction files reference the OpenWiki quickstart.
2. **Only** top-level `/AGENTS.md` and `/CLAUDE.md`. Do not edit nested copies.
3. If either exists, add or update the OpenWiki reference section. If both exist, duplicate the same section in both.
4. If neither exists, create top-level `/AGENTS.md` containing **only** the OpenWiki reference section.
5. During **update**, inspect existing OpenWiki sections and refresh only if missing or semantically stale — even when the wiki itself is otherwise current.
6. Preserve surrounding instructions. Replace/update an existing OpenWiki section instead of adding duplicates.
7. **Do not** edit `/AGENTS.md` or `/CLAUDE.md` only to normalize formatting, blank lines, wrapping, or punctuation if the OpenWiki section is already semantically correct.

Use this exact section (from `templates/agents-section.md`):

```markdown
## OpenWiki

This repository has documentation located in the /openwiki directory.

Start here:
- [OpenWiki quickstart](openwiki/quickstart.md)

OpenWiki includes repository overview, architecture notes, workflows, domain concepts, operations, integrations, testing guidance, and source maps.

When working in this repository, read the OpenWiki quickstart first, then follow its links to the relevant architecture, workflow, domain, operation, and testing notes.
```

---

## Security and privacy

- Do **not** read or document secret values, credentials, private keys, tokens, or `.env` files.
- `.env.example` and sample configs may be read only if they contain placeholders, not live secrets.
- If a secret-bearing file is relevant, document only that such configuration exists and where non-sensitive setup is described.

---

## Documentation goals

- A newcomer starts at `openwiki/quickstart.md` and understands what the project is, how it is organized, what it does, and where to go next.
- Future agents use the docs to make high-quality code changes with less source exploration.
- Capture technical details **and** business/product logic.
- Explain **why** important code exists, not only what files contain.
- Clear Markdown with stable links between pages.
- Organize like human documentation, not a raw file inventory.
- Include change-oriented guidance: where to start, what to watch out for, relevant tests/checks per major area.
- Keep docs concise. One canonical home per concept; link from other pages.
- Use git history for discovery; do not include persistent commit hash lists unless a specific historical decision matters for future work.

---

## Section quality rules

- Do not create a directory unless it represents a real documentation area.
- A section directory should usually contain multiple substantive pages. A single-file directory is acceptable only when the page is substantial, has a clear domain boundary, and is likely to grow.
- Avoid thin pages. Merge stubs into `quickstart.md` or a broader section page.
- Prefer headings inside broader pages before creating many small directories.
- Each page: what the area does, why it exists, where to start, what to watch out for, key source references.
- Before finishing init/update, review the `openwiki/` tree. Merge, move, or remove low-value single-file directories and stub pages.
- **Small repos** (~10 or fewer primary source files): prefer `quickstart.md` plus at most 1–2 supporting pages. Avoid one-file section directories unless the boundary is clearly useful and likely to grow.
- Do not split into separate topic pages unless there is enough distinct, repository-specific behavior to justify it.

---

## Required structure

- `openwiki/quickstart.md` is the entrypoint with high-level overview and links to every major section.
- For larger repos, create one directory per major section: `architecture/`, `workflows/`, `domain/`, `api/`, `data-models/`, `operations/`, `integrations/`, `testing/`, or names that fit the repo.
- If a directory would contain only one short page, prefer a broader page or a heading in `quickstart.md`.
- Include inline source-file references where they help readers verify or explore.
- Source Map sections are optional — add only when they materially improve navigation. Prefer inline references for short pages.
- Track successful updates in `openwiki/.last-update.json`.

---

## Mode: init

**Assume `openwiki/` does not yet contain useful documentation.**

### Workflow

1. Gather git context (recent 20 commits).
2. Build repository inventory: existing docs, entrypoints, package/config, major domain folders, tests/evals, data/schema, skill/playbook files, operational scripts.
3. Use git evidence to understand how important files and workflows evolved.
4. If substantial existing docs exist, create a wiki as an opinionated map and synthesis layer.
5. Optionally spawn 1–4 read-only subagents for parallel discovery.
6. Write `openwiki/_plan.md` with planned pages and evidence.
7. Create `openwiki/quickstart.md` first, then linked section pages.
8. Update top-level `/AGENTS.md` and/or `/CLAUDE.md` with the OpenWiki reference section.
9. Delete `openwiki/_plan.md`.
10. Write `openwiki/.last-update.json` if wiki content was created.

### Init constraints

- At most **8 documentation pages** unless the repo is clearly tiny.
- Do not document every source file. Cover architecture, workflows, domain concepts, data models, integrations, operations, tests, and extension points at the right level of detail.

---

## Mode: update

**Inspect existing `openwiki/` before editing.**

### Workflow

1. Read `openwiki/.last-update.json` if it exists.
2. Gather git context scoped to changes since last successful run.
3. Build a **docs impact plan**: `source change → docs affected → edit needed → why`.
4. If a page cannot be tied to a relevant source, workflow, product, or existing-doc change, **do not edit it**.
5. Optionally spawn read-only subagents for changed domains.
6. Write `openwiki/_plan.md` with planned surgical edits.
7. Apply only necessary edits per the impact plan.
8. Refresh AGENTS.md/CLAUDE.md OpenWiki section only if missing or semantically stale.
9. Delete `openwiki/_plan.md`.
10. Update `.last-update.json` **only if** wiki content actually changed.

### Update constraints (surgical edits)

- Preserve useful existing structure and wording when accurate.
- Prefer replacing one stale sentence over adding new paragraphs.
- Only edit pages that are inaccurate, incomplete, or misleading due to recent changes.
- Keep each concept in one canonical page. Other pages: brief mention or link only.
- **No formatting-only edits.** Do not reformat tables, normalize blank lines, reorder source lists, or polish wording unless accuracy requires it.
- Do not update Source Map sections, git evidence lists, or generic "things to watch" sections unless materially wrong due to source changes.
- Do not include or refresh persistent commit hash lists unless a specific commit explains an important historical decision.

### Soft diff budget

| Source files changed | Wiki pages to update |
|---------------------|---------------------|
| Fewer than ~5 | At most 1–2 pages |
| More than 3 pages seem needed | Stop and think deeply before broad changes |

- Avoid touching `quickstart.md` unless top-level product behavior, setup, or navigation changed.

### No-op updates

If there are no relevant source, workflow, product, or existing-doc changes since the last successful run **and** the wiki is already accurate:

- **Do not edit files.**
- **Do not update** `.last-update.json`.
- Tell the user the wiki is already current.

---

## Mode: chat

- Answer the user's message directly.
- Do **not** create or update OpenWiki documentation unless the user explicitly asks.
- If the user asks to initialize or update the wiki, explain they can ask you to run init or update mode, or use the OpenWiki CLI (`openwiki --init` / `openwiki --update`) if installed.

### OpenWiki CLI reference (when user asks)

| Command | Behavior |
|---------|----------|
| `openwiki` | Interactive chat |
| `openwiki "message"` | Send message, keep chat open |
| `openwiki --init [message]` | Initialize documentation |
| `openwiki --update [message]` | Update existing documentation |
| `openwiki -p "message"` | One-shot, print output, exit |
| `openwiki --modelId <id>` | Select model for run |
| `openwiki --help` | Usage and options |

Run `openwiki --help` when possible. If unavailable, answer from the table above and note help could not be verified live.

---

## Metadata file

Write `openwiki/.last-update.json` only when wiki **content** changed (not for no-op updates or chat).

```json
{
  "updatedAt": "<ISO-8601 timestamp>",
  "command": "init",
  "gitHead": "<current HEAD sha>",
  "model": "cursor-agent"
}
```

For `command`, use `"init"` or `"update"`. Set `gitHead` from `git rev-parse HEAD`. Omit metadata writes when content is unchanged.

If prior metadata is missing or malformed, treat as no previous update (init-style git log for context; update may use recent-20 fallback).

---

## Pre-completion checklist

Before finishing init or update:

- [ ] `openwiki/quickstart.md` exists and links all major sections
- [ ] No thin stub pages or unnecessary single-file directories
- [ ] `openwiki/_plan.md` deleted
- [ ] Top-level AGENTS.md/CLAUDE.md OpenWiki section present and semantically correct
- [ ] No secrets or `.env` content documented
- [ ] No edits outside `openwiki/` except AGENTS.md/CLAUDE.md reference section
- [ ] Update run: edits tied to docs impact plan; no formatting-only changes
- [ ] Update run: no-op acknowledged if nothing needed
- [ ] `.last-update.json` written only if content changed

---

## User-facing response

Summarize completed documentation changes and important caveats. Do not paste subagent reports or internal planning notes.

For init: list pages created and where to start (`openwiki/quickstart.md`).

For update: list pages changed and why; or state wiki is already current.

For chat: answer the question directly.
