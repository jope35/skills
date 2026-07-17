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

1. Gather recent git context, normally the latest 20 commits.
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
2. Gather commits since `gitHead`; fall back to `updatedAt`, then recent history.
3. Include uncommitted changes from `git status` and `git diff`.
4. Build a docs impact plan:

   ```text
   source change -> docs affected -> edit needed -> why
   ```

5. If a page cannot be tied to a relevant source, workflow, product, or authoritative-doc change, do not edit it.
6. Optionally delegate read-only research for changed domains.
7. Write `_plan.md` with only the planned surgical edits and affected relationships.
8. Apply necessary factual and graph changes.
9. Promote a backlog entry when recent changes touch it or spare documentation budget permits; remove the entry once documented.
10. Delete `_plan.md`.
11. Update `.last-update.json` only when the final content snapshot differs.

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

### No-op

If no relevant changes affect an already accurate wiki:

- Do not edit generated pages.
- Do not update `.last-update.json`.
- Report that the wiki is current.

A no-op is correct update behavior.

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

## Git context commands

Run from the target repository root.

### Always

```bash
git --no-pager status --short
git --no-pager rev-parse HEAD
git --no-pager diff --name-status HEAD
```

### Init or missing prior metadata

```bash
git --no-pager log --max-count=20 --name-status --oneline
```

### Update with `gitHead`

```bash
git --no-pager log <gitHead>..HEAD --name-status --oneline
```

### Update with only `updatedAt`

```bash
git --no-pager log --since "<updatedAt ISO timestamp>" --name-status --oneline
```

Use the installed skill helper with the target repository as cwd:

```bash
cd /path/to/target-repo
bash /path/to/installed-skill/scripts/gather-git-context.sh init
bash /path/to/installed-skill/scripts/gather-git-context.sh update
```
