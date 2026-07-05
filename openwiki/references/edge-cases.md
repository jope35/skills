# OpenWiki edge cases and quality rules

All rules from [langchain-ai/openwiki `prompt.ts`](https://github.com/langchain-ai/openwiki/blob/main/src/agent/prompt.ts). Apply during init and update unless noted.

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

## Metadata edge cases

### When to write `.last-update.json`

- Write only when wiki **content** changed (init or update that modified files).
- Do **not** write for no-op updates or chat mode.
- Compare content before and after: if identical, skip metadata update.

### Malformed or missing prior metadata

- Missing file → treat as no previous update.
- Invalid JSON or missing required fields (`updatedAt`, `command`, `model` in original schema) → treat as no previous update.
- For update git context: prefer `gitHead`; fall back to `updatedAt`; if neither, use recent-20 log and note no prior timestamp.

### `command` field normalization

- Record `"init"` or `"update"` to match the run mode.
- If prior metadata has an unexpected `command` value, still use it for context but do not let it block a valid update.

## Update-specific edge cases

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

## Agent instruction file edge cases

- **Top-level only.** Never edit nested `AGENTS.md` or `CLAUDE.md`.
- **Both files exist:** duplicate the same OpenWiki section in both.
- **Neither exists:** create `/AGENTS.md` with only the OpenWiki section.
- **Section already correct:** do not edit for formatting normalization.
- **Stale section:** replace the existing OpenWiki section; do not add a second one.
- **User opts out:** skip all instruction-file edits if the user explicitly requests it.

## Security edge cases

- Never read `.env` files.
- Never document live tokens, keys, or credentials found in source.
- For config that references secrets, document the **existence** of configuration and point to `.env.example` or setup docs.
- Sample configs with placeholders only may be read.

## Delegation edge cases

- Delegates are **read-only**. Any write by a delegate is a violation — the primary agent owns all writes.
- Do not paste delegate output into user-facing responses.
- Default to fewer delegates on large/unfamiliar repos (1–2), not more.
- Use more delegates (3–4) only for small/medium repos with clearly independent domains or explicit user request.

## Planning file edge cases

- `_plan.md` is **temporary** and must not appear in the final wiki.
- Create it after discovery, before final writes.
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
