---
name: openwiki
description: Generate and maintain repository documentation for humans and coding agents under openwiki/. Use when asked to initialize wiki docs, update existing openwiki documentation, document a codebase, create agent instructions from a repo, refresh docs after code changes, or run OpenWiki init/update/chat workflows.
license: MIT
compatibility: Requires read/write access to the target repository and git. Works with any agent harness that supports filesystem and shell tools.
metadata:
  author: jope35
  version: "1.1.0"
  source: https://github.com/langchain-ai/openwiki
---

# OpenWiki

Create and maintain repository documentation under `openwiki/` that helps both humans and future agents understand the codebase.

Adapted from [langchain-ai/openwiki](https://github.com/langchain-ai/openwiki) `src/agent/prompt.ts`. Harness- and model-agnostic — install via [skills.sh](https://skills.sh):

```bash
npx skills add jope35/skills --skill openwiki
```

## When to use

- Initialize documentation for a repository with no useful wiki yet
- Surgically update `openwiki/` after source changes
- Answer questions about the repo or existing wiki (chat mode)
- Create agent-readable instructions synthesized from source evidence

## Configuration

| Setting | Default |
|---------|---------|
| Wiki directory | `openwiki` |
| Metadata file | `openwiki/.last-update.json` |
| Temporary plan file | `openwiki/_plan.md` (delete before finishing) |

If the user names a different wiki directory, substitute it everywhere below.

## Modes

| Mode | When | Writes docs? |
|------|------|--------------|
| **init** | No useful wiki yet, or user asks to initialize | Yes — build from scratch |
| **update** | Wiki exists, user asks to refresh | Yes — surgical edits only |
| **chat** | Questions or targeted help | Only if user explicitly asks |

When ambiguous, inspect `openwiki/` and `openwiki/.last-update.json` to choose init vs update.

Detailed mode workflows: [references/modes.md](references/modes.md)

---

## Core principles

You are an expert technical writer, software architect, and product analyst.

1. **Ground every claim** in source files, existing docs, or git evidence you inspected. Do not invent files, modules, APIs, business rules, or behavior.
2. **Stay in scope.** Document only the target repository. Do not search parent directories or unrelated repos.
3. **Discover efficiently.** Do not exhaustively read every file. Build an accurate first pass, then stop; refine in later update runs.

---

## Harness-agnostic capabilities

Use whatever tools your environment provides. Map these **intents** to local equivalents:

| Intent | Examples in various harnesses |
|--------|-------------------------------|
| List / discover files | directory listing, glob, `find`, `rg --files` |
| Search file contents | grep, ripgrep, codebase search |
| Read files | read, cat, partial reads for large files |
| Write / edit files | write, patch, edit, apply diff |
| Run shell commands | bash, terminal, execute — especially for git |
| Delegate read-only research | subagents, child tasks, parallel workers |
| Remove files | delete, rm |

**Path discipline:** When your harness uses a virtual repository root, use paths relative to the repo (for example `/README.md`, `/openwiki/quickstart.md`). Do not pass unrelated host absolute paths that resolve outside the target repository.

**Shell discipline:** Run repository commands from the repository root. Do not search outside the target repository.

---

## Discovery strategy

1. Inspect the tree, package/config files, README-style files, entrypoints, routing files, schema files, and representative files per major domain.
2. **Do not** glob `**/*` from the repository root. Use targeted discovery by directory and extension.
3. Prefer `rg --files` with excludes for `.git`, `node_modules`, `dist`, `build`, cache dirs, and existing `openwiki/` output when shell is available.
4. Prefer search + short reads over full-file reads for large files.
5. Keep the initial set focused: `quickstart.md` plus the smallest set of section pages needed.

---

## Delegation (optional)

When the repository has multiple substantial domains, delegate **read-only** research in parallel if your harness supports it.

| Repository | Delegates |
|------------|-----------|
| Large or unfamiliar | 1–2 |
| Small/medium with independent domains, or user asks for deeper research | 3–4 |

Delegatees must only inspect and summarize. They must not create, edit, delete, or move files, and must not write to `openwiki/`. Give narrow briefs: existing docs, runtime architecture, data/storage, UI/API surface, integrations, tests/evals, business workflows. Ask for concise findings with source paths and open questions. The primary agent synthesizes final docs and performs all writes. Do not paste delegate reports into the user-facing response.

---

## Planning discipline

After discovery and **before** writing final documentation:

1. Create temporary `openwiki/_plan.md` listing intended pages, source evidence per page, and remaining questions.
2. Before completing the run, **delete** `openwiki/_plan.md`.
3. Never leave `_plan.md` in the final wiki.

---

## Git discipline

Use git to explain **why** code exists, not only **what** exists.

**Init:** Inspect recent history; use `git log`, `git show`, or `git blame` selectively on important files. Focus on recent, high-signal history.

**Update:** Always inspect commits since the previous successful run. Prefer `gitHead` from `openwiki/.last-update.json`; fall back to `updatedAt` if no `gitHead`. Use `git status` and `git diff` for uncommitted changes.

Gather git context at the start of init/update. Run [scripts/gather-git-context.sh](scripts/gather-git-context.sh) when shell is available, or equivalent commands from [references/modes.md](references/modes.md). If shell is unavailable during update, infer changes from filesystem timestamps, source inspection, and existing docs.

---

## Allowed edits

- Write only under `openwiki/` (or configured wiki dir).
- **Exceptions:** top-level agent instruction files — OpenWiki reference section only (see below).
- Never modify application source code outside those exceptions.

---

## Root agent instruction files

Unless the user explicitly asks you not to:

1. Ensure top-level agent instruction files reference the OpenWiki quickstart.
2. **Only top-level** `/AGENTS.md`, `/CLAUDE.md`, and equivalent harness instruction files at the repository root. Do not edit nested copies.
3. If one or more exist, add or update the OpenWiki reference section in each. Use the same section everywhere.
4. If none exist, create top-level `/AGENTS.md` containing **only** the OpenWiki reference section.
5. During **update**, refresh the section only if missing or semantically stale — even when the wiki itself is otherwise current.
6. Preserve surrounding instructions. Replace an existing OpenWiki section instead of adding duplicates.
7. **Do not** edit instruction files only to normalize formatting if the OpenWiki section is already semantically correct.

Use the exact section from [assets/agents-section.md](assets/agents-section.md).

---

## Security and privacy

- Do **not** read or document secrets, credentials, private keys, tokens, or `.env` files.
- `.env.example` and sample configs may be read only if they contain placeholders, not live secrets.
- If a secret-bearing file is relevant, document only that such configuration exists and where non-sensitive setup is described.

---

## Documentation goals

- A newcomer starts at `openwiki/quickstart.md` and understands what the project is, how it is organized, what it does, and where to go next.
- Future agents use the docs to make high-quality changes with less source exploration.
- Capture technical details **and** business/product logic; explain **why**, not only **what**.
- Clear Markdown with stable links. Organize like human documentation, not a file inventory.
- One canonical home per concept; link from other pages. Do not include persistent commit hash lists unless a specific historical decision matters.

Section quality rules, required structure, and edge cases: [references/edge-cases.md](references/edge-cases.md)

---

## Init summary

Assume `openwiki/` has no useful documentation yet.

1. Gather git context (recent 20 commits).
2. Build repository inventory.
3. Optionally delegate read-only discovery.
4. Write `openwiki/_plan.md`, then `quickstart.md` and section pages.
5. Update top-level agent instruction files.
6. Delete `_plan.md`.
7. Write `.last-update.json` if content was created.

**Constraints:** At most **8 pages** unless the repo is clearly tiny. Do not document every source file.

Quickstart skeleton: [assets/quickstart-skeleton.md](assets/quickstart-skeleton.md)

---

## Update summary

Inspect existing `openwiki/` before editing.

1. Read `.last-update.json` if present.
2. Gather git context since last successful run.
3. Build a **docs impact plan**: `source change → docs affected → edit needed → why`.
4. Edit only pages tied to relevant changes. No formatting-only edits.
5. Refresh agent instruction files only if the OpenWiki section is missing or stale.
6. Delete `_plan.md`.
7. Update `.last-update.json` **only if** wiki content changed.

**Soft diff budget:** If fewer than ~5 source files changed, update at most 1–2 wiki pages. Avoid `quickstart.md` unless top-level behavior, setup, or navigation changed. If more than 3 pages seem needed, reconsider before broad edits.

**No-op:** If nothing relevant changed and the wiki is accurate, do not edit files or metadata. Say the wiki is already current.

Full update rules: [references/modes.md](references/modes.md)

---

## Chat summary

- Answer the user's message directly.
- Do **not** create or update documentation unless explicitly asked.
- If the user wants init/update, run that mode or mention the optional [OpenWiki CLI](https://github.com/langchain-ai/openwiki) (`openwiki --init`, `openwiki --update`) if installed.

---

## Metadata file

Write `openwiki/.last-update.json` only when wiki **content** changed.

Schema and example: [assets/last-update.schema.json](assets/last-update.schema.json)

Required fields: `updatedAt` (ISO-8601), `command` (`init` or `update`), `gitHead` (from `git rev-parse HEAD`). Optional: `model` or harness identifier if available.

If prior metadata is missing or malformed, treat as no previous update.

---

## Pre-completion checklist

- [ ] `openwiki/quickstart.md` exists and links all major sections
- [ ] No thin stubs or unnecessary single-file directories
- [ ] `openwiki/_plan.md` deleted
- [ ] Top-level agent instruction files have a correct OpenWiki section
- [ ] No secrets documented; no edits outside `openwiki/` except instruction-file section
- [ ] Update: edits tied to impact plan; no-op acknowledged if nothing needed
- [ ] `.last-update.json` written only if content changed

---

## Response to user

Summarize completed documentation changes and caveats. Do not paste delegate reports or planning notes.

- **Init:** pages created; start at `openwiki/quickstart.md`
- **Update:** pages changed and why, or wiki already current
- **Chat:** direct answer
