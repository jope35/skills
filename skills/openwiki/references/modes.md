# OpenWiki code mode — detailed workflows

These workflows implement the repository output mode from OpenWiki 0.2.0. The target repository is the runtime root and generated pages live under `openwiki/`.

## Shared setup

Before init or update:

1. Run from the target repository root.
2. Record a content snapshot of `openwiki/`, excluding `.last-update.json`.
3. Read `openwiki/INSTRUCTIONS.md` when present. It is the user-authored scope brief; do not edit it during routine runs.
4. Inspect existing wiki structure and metadata.
5. Gather git status, HEAD, relevant history, and working-tree changes.
6. Create an OKF-compliant `openwiki/_plan.md` after discovery and before final writes.
7. Do not create or edit deterministic `index.md` files.
8. Do not create or edit `AGENTS.md` or `CLAUDE.md`; OpenWiki's CLI manages its own marked snippets.

## Init

Assume `openwiki/` does not yet contain useful generated documentation.

### Workflow

1. Gather compact git context with the helper (defaults to the latest 15 commits).
2. Build a repository inventory:
   - existing docs, README files, `docs/`, runbooks, and `SKILL.md` files
   - application and graph entrypoints, package/config files, routing
   - major domains, data/schema files, integrations, tests/evals
   - operational scripts, playbooks, and extension points
3. Use targeted `git show` or `git blame` to understand important decisions.
4. If substantial docs already exist, make the wiki an opinionated map and synthesis layer rather than a duplicate.
5. Optionally delegate read-only discovery for independent domains.
6. Write `_plan.md` with intended concepts, evidence, questions, and relationship triples.
7. Create `quickstart.md` first, then the smallest useful set of linked concept pages.
8. Add OKF front matter and evidence-backed semantic links.
9. Put deferred real areas in `quickstart.md` under `## Backlog`.
10. Delete `_plan.md`.
11. Write `.last-update.json` only if the final content snapshot differs from the initial snapshot.

### Init constraints

- Use at most 8 generated documentation pages unless the repository is clearly tiny.
- Do not document every source file.
- For repositories with about 10 or fewer primary source files, prefer quickstart plus at most 1–2 supporting pages.
- Every identified area must be documented or backlogged with an area name, source anchor, and reason.

## Update

Inspect existing `openwiki/` before editing.

### Workflow

1. Read `quickstart.md`, including `## Backlog`, and `.last-update.json`.
2. Gather compact git context with the helper. Read the `pre-noop` line first.
3. If `pre-noop` starts with `skip —` and the user did not request a specific documentation change, stop immediately: do not invent edits, do not write metadata, and report that the wiki is current.
4. Otherwise gather commits since `gitHead`; when prior metadata has no `gitHead`, fall back to `updatedAt`, then recent history.
5. Include uncommitted changes from status and worktree sections.
6. Build a docs impact plan:

   ```text
   source change -> docs affected -> edit needed -> why
   ```

7. If a page cannot be tied to a relevant source, workflow, product, or authoritative-doc change, do not edit it.
8. Optionally delegate read-only research for changed domains.
9. Write `_plan.md` with only the planned surgical edits and affected relationships.
10. Apply necessary factual and graph changes, including removing obsolete claims.
11. Promote a backlog entry when recent changes touch it or spare documentation budget permits; remove the entry once documented.
12. Delete `_plan.md`.
13. Update `.last-update.json` only when the final content snapshot differs.

### Surgical rules

- Preserve useful structure and wording when accurate.
- Prefer replacing one stale sentence over adding broad prose.
- Keep each concept in one canonical page; use brief links elsewhere.
- Do not make formatting-only edits.
- Do not normalize tables, blank lines, wrapping, or source-list order unless the surrounding content must change.
- Do not refresh source maps, generic watchlists, or git evidence lists unless materially wrong.
- Do not add or refresh commit hash lists unless one commit explains an important decision.
- Correct OKF front matter on a page when that page is already being substantively updated; do not churn every page's metadata.

### Soft diff budget

| Change scope | Expected wiki scope |
|--------------|---------------------|
| Fewer than about 5 source files | At most 1–2 pages |
| More than 3 pages appear affected | Reconsider before broad edits |

Avoid `quickstart.md` unless top-level behavior, setup, or navigation changed.

### Pre-noop skip (before discovery)

OpenWiki 0.2's CLI can skip the agent before discovery when an update has no meaningful repository change. Portable runs should do the same after gathering git context:

Skip the update run when all of these are true:

1. Prior metadata has a `gitHead`.
2. The worktree is clean aside from `openwiki/.last-update.json`.
3. Either `HEAD == gitHead`, or every path changed since `gitHead` is under `openwiki/`.

Do **not** skip when:

- prior `gitHead` is missing
- the worktree has non-metadata changes
- any non-`openwiki/` path changed since `gitHead`
- the user explicitly asked for a documentation change in this turn

The helper emits this as `pre-noop` with either `skip — <reason>` or `run — <reason>`.

### Post-discovery no-op

If the run proceeds and no relevant changes affect an already accurate wiki:

- Do not edit generated pages.
- Do not update `.last-update.json`.
- Report that the wiki is current.

Both pre-noop skip and post-discovery no-op are correct update behavior.

## Chat

- Answer directly.
- Read `openwiki/` first; inspect source when the wiki is insufficient or the user asks for source-level evidence.
- Do not modify documentation unless explicitly asked.
- If the user requests repository initialization or maintenance, run init/update or mention:

| Command | Behavior |
|---------|----------|
| `openwiki` | Interactive code-mode chat for the current repository |
| `openwiki "message"` | Send a code-mode message and keep chat open |
| `openwiki code --init [message]` | Initialize repository documentation |
| `openwiki code --update [message]` | Update repository documentation |
| `openwiki --init [message]` | Initialize repository documentation; bare init defaults to code mode |
| `openwiki --update [message]` | Update repository documentation; bare update defaults to code mode |
| `openwiki -p "message"` | One-shot output |
| `openwiki --modelId <id>` | Select a model for the run |
| `openwiki --help` | Print current usage |

Run `openwiki --help` when possible if the user asks about CLI behavior.

## Git context helper

Prefer the skill helper. It emits compact RTK-inspired context instead of raw command dumps. Use skill-root-relative paths:

```bash
OPENWIKI_TARGET_REPO=/path/to/target-repo bash scripts/gather-git-context.sh init
OPENWIKI_TARGET_REPO=/path/to/target-repo bash scripts/gather-git-context.sh update
```

Typical output sections:

| Section | Meaning |
|---------|---------|
| `head` | Current `HEAD` SHA |
| `prior` | Previous `gitHead`, `updatedAt`, or `none` |
| `pre-noop` | Update-only skip/run assessment |
| `status` | Porcelain branch + changed paths, grouped when dense |
| `log …` | Recent or since-last-update commits with capped file lists |
| `worktree` | Staged and unstaged name-status paths |

Defaults can be overridden with `OPENWIKI_GIT_LOG_LIMIT_INIT`, `OPENWIKI_GIT_LOG_LIMIT_UPDATE`, `OPENWIKI_GIT_MAX_FILES_PER_COMMIT`, and `OPENWIKI_GIT_MAX_SUBJECT`.

If the helper is unavailable, gather equivalent evidence manually with:

```bash
git --no-pager rev-parse HEAD
git --no-pager status --porcelain=v1 -b --untracked-files=all
git --no-pager log --max-count=15 --name-status --pretty=format:'%h %s (%ar) <%an>'
git --no-pager diff --name-status HEAD
git --no-pager diff --cached --name-status HEAD
```

For update with prior `gitHead`, replace the log command with:

```bash
git --no-pager log <gitHead>..HEAD --name-status --pretty=format:'%h %s (%ar) <%an>'
```

For update with only `updatedAt`:

```bash
git --no-pager log --since "<updatedAt ISO timestamp>" --name-status --pretty=format:'%h %s (%ar) <%an>'
```
