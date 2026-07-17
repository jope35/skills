# OpenWiki code-mode edge cases and quality rules

These rules follow the repository output mode in [langchain-ai/openwiki 0.2.0 `prompt.ts`](https://github.com/langchain-ai/openwiki/blob/0.2.0/src/agent/prompt.ts).

## Repository wiki brief

- Read `openwiki/INSTRUCTIONS.md` before planning when it exists.
- Treat it as user-authored control metadata, not generated documentation.
- Do not rewrite it during routine init/update/chat runs.
- Change it only when the user explicitly asks to alter repository wiki scope or priorities.

## Existing documentation

- Treat README files, `docs/` trees, root documentation, runbooks, and `SKILL.md` files as primary source material.
- Summarize and link to existing docs when still useful — do not duplicate wholesale.
- If existing docs conflict with source code or git history, call out likely stale documentation and prefer current source evidence.

## Section quality

- Do not create a directory unless it represents a real documentation area.
- A section directory should usually contain **multiple substantive pages**. A single-file directory is acceptable only when the page is substantial, has a clear domain boundary, and is likely to grow.
- Avoid thin pages. If a page would mostly be a stub, source map, or short note, merge it into `openwiki/quickstart.md` or a broader section page.
- Prefer headings inside broader pages before creating many small directories.
- Each page should provide real value: what the area does, why it exists, where to start, what to watch out for, key source references.
- Before finishing init/update, review the `openwiki/` tree. Merge, move, or remove low-value single-file directories and stub pages.

### Small repositories

When the repo has about **10 or fewer primary source files**:

- Prefer `quickstart.md` plus at most **1–2 supporting pages**.
- Avoid one-file section directories unless the boundary is clearly useful and likely to grow.

### Page splits

Do not split content into separate topic pages unless there is enough distinct, repository-specific behavior to justify the split.

## Required structure

- `openwiki/quickstart.md` must be the entrypoint.
- `quickstart.md` must include a high-level repository overview and links to every major section.
- For larger repos, create one directory per major section: `architecture/`, `workflows/`, `domain/`, `api/`, `data-models/`, `operations/`, `integrations/`, `testing/`, or names that fit the repo.
- If a directory would contain only one short page, prefer a broader page or a heading in `quickstart.md`.
- Include inline source-file references where they help readers verify or explore.
- **Source Map sections are optional.** Add one only when it materially improves navigation. Prefer inline references for short pages.
- Keep deferred areas in `quickstart.md` under `## Backlog`; do not create a separate backlog page.
- Every backlog entry needs an area name, source anchor, and one-line reason.

## OKF and concept graph

- Every Markdown page created or substantively updated, including `_plan.md`, needs valid OKF front matter with `type`, `title`, `description`, and `tags`; `resource` is optional.
- Do not add front matter fields outside that schema.
- Correct front matter on pages already being substantively updated; do not churn untouched pages solely to normalize metadata.
- Put concept links in prose that explains the evidence-backed relationship.
- Quickstart navigation and generated index links do not count as semantic concept relationships.
- When evidence supports it, connect a substantive concept to at least two other substantive concepts.
- Merge unsupported or thin concepts rather than creating pages solely to increase graph density.
- Before completion, verify internal links and ensure no concept is accidentally orphaned.

## Generated indexes

- OpenWiki 0.2 generates directory `index.md` files deterministically after a CLI run.
- Do not create or hand-edit `index.md`.
- In a harness without index generation, use `quickstart.md` for navigation and preserve existing indexes.

## Metadata edge cases

### When to write `.last-update.json`

- Write only when wiki **content** changed (init or update that modified files).
- Do **not** write for no-op updates or chat mode.
- **Verify with a content snapshot:** hash `openwiki/` before and after the run, excluding `.last-update.json`. If fingerprints match, skip metadata even if files were read or a plan was drafted.
- Use `scripts/snapshot-wiki-content.sh` with `OPENWIKI_TARGET_REPO` set to the target repository (skill-root-relative path), or equivalent manual comparison without shell.

### Malformed or missing prior metadata

- Missing file → treat as no previous update.
- Invalid JSON or missing required fields (`updatedAt`, `command`, `model`) → treat as no previous successful code-mode update.
- A missing `gitHead` is valid. Fall back to `updatedAt` for git scoping.
- For update git context: prefer `gitHead`; fall back to `updatedAt`; if neither, use the helper's recent log and note no prior timestamp.

### `command` field normalization

- Record `"init"` or `"update"` to match the run mode.
- If prior metadata has an unexpected `command` value, still use it for context but do not let it block a valid update.

## Update-specific edge cases

### Pre-noop skip before discovery

Upstream OpenWiki 0.2 can skip the agent before discovery when an update has no meaningful repository change (`getUpdateNoopStatus` in `src/agent/utils.ts`). Portable runs should mirror that:

Skip when:

- prior metadata has `gitHead`
- worktree is clean aside from `openwiki/.last-update.json`
- and either `HEAD == gitHead`, or every changed path since `gitHead` is under `openwiki/`

Do not skip when prior `gitHead` is missing, the worktree has other changes, any non-`openwiki/` path changed, or the user explicitly asked for a documentation change.

The gather-git-context helper emits this as `pre-noop: skip — …` or `pre-noop: run — …`. On `skip`, stop before planning or writing.

### Docs impact plan required

Before editing in update mode, every page change must trace to:

- a changed source file, or
- a changed workflow/product behavior, or
- a changed existing doc that the wiki references, or
- inaccurate/misleading content caused by recent changes

If a page cannot be tied to any of these, **do not edit it**.

### Formatting-only prohibition

During update, do **not**:

- reformat Markdown tables
- normalize blank lines or wrapping
- reorder source lists for aesthetics
- polish wording when facts are unchanged
- refresh Source Maps, git evidence lists, or generic watchlists when still accurate
- add or refresh commit hash lists unless a specific commit explains an important decision

### Canonical content

If the same detail appears in multiple pages:

- Keep the detailed explanation in **one canonical page**.
- Other pages: brief mention or link only.

### Quickstart touch threshold

Do not update `quickstart.md` unless:

- top-level product behavior changed, or
- setup instructions changed, or
- navigation structure changed (new/removed major sections)

## Init-specific edge cases

### Existing partial wiki

- If `openwiki/` exists but is empty or stub-only, treat as init.
- If substantial wiki exists but user asks to init, clarify intent — prefer update unless user wants a full rebuild.

### Existing substantial docs outside `openwiki/`

- Create the wiki as a synthesis layer and navigation map.
- Link to authoritative existing docs rather than copying them.

### Page budget

- Default max: **8 pages** on initial run.
- Tiny repos: `quickstart.md` + 0–2 supporting pages is often enough.
- Do not silently drop domains because of the page budget; add concise backlog entries.

## Agent instruction file edge cases

- Do not create or edit root or nested `AGENTS.md` or `CLAUDE.md` during routine wiki runs.
- OpenWiki's code-mode CLI owns the `<!-- OPENWIKI:START -->` / `<!-- OPENWIKI:END -->` root-agent snippets.
- Existing OpenWiki references are context only; leave them untouched unless the user explicitly asks for a separate agent-instruction change.
- Never add a second OpenWiki section to compensate for a stale CLI-managed block.

## Security edge cases

- Never read `.env` files.
- Never document live tokens, keys, or credentials found in source.
- For config that references secrets, document the **existence** of configuration and point to `.env.example` or setup docs.
- Sample configs with placeholders only may be read.

## Delegation edge cases

- Delegates are read-only by default; the primary agent owns all writes.
- Exception: a dedicated OKF migration may assign one subagent per wiki directory and restrict each writer to Markdown files directly inside that directory.
- During that migration, change front matter only; preserve bodies exactly, skip `index.md`, and do not create, delete, move, rename, or reorganize pages.
- Inventory all wiki directories first and verify that each was processed.
- Do not paste delegate output into user-facing responses.
- Default to fewer delegates on large/unfamiliar repos (1–2), not more.
- Use more delegates (3–4) only for small/medium repos with clearly independent domains or explicit user request.

## Planning file edge cases

- `_plan.md` is **temporary** and must not appear in the final wiki.
- Create it after discovery, before final writes.
- Give it OKF front matter and include intended relationship triples.
- Delete it before completing the run.
- If no delete capability exists, use shell: `rm -f openwiki/_plan.md`

## Virtual path edge cases (harnesses with virtual roots)

- Use repository-relative paths: `/README.md`, `/src/main.ts`, `/openwiki/quickstart.md`
- Do not pass host absolute paths (for example `/Users/.../repo/README.md`) to virtual filesystem tools — they may create nested paths inside the repo instead of touching the intended file.
- Shell commands run on the host: `cd` to the repository root before git or other repo commands.

## Discovery edge cases

- Do not call glob with `**/*` from repository root.
- Exclude generated output: `.git`, `node_modules`, `dist`, `build`, cache dirs, existing `openwiki/`.
- Prefer targeted reads; do not read every file in the repository.
