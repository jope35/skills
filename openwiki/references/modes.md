# OpenWiki modes — detailed workflows

## Init mode

**Assume `openwiki/` does not yet contain useful documentation.**

### Workflow

1. Record a **content snapshot** of `openwiki/` (excluding `.last-update.json`) before writing.
2. Gather git context (recent 20 commits).
3. Build repository inventory:
   - existing docs, README, `docs/`, `SKILL.md` files
   - graph/app entrypoints, package/config files
   - major domain folders, tests/evals, data/schema files
   - skill/playbook files, operational scripts
4. Use git evidence to understand how important files and workflows evolved. Prefer recent commits and targeted `git blame` / `git show` on high-signal files.
5. If substantial existing docs exist, create a wiki as an opinionated map and synthesis layer — summarize and link rather than duplicate.
6. Optionally delegate 1–4 read-only workers for parallel discovery.
7. Write `openwiki/_plan.md` with planned pages and evidence.
8. Create `openwiki/quickstart.md` first, then linked section pages.
9. Update top-level agent instruction files with the OpenWiki reference section.
10. Delete `openwiki/_plan.md`.
11. Write `openwiki/.last-update.json` only if the post-run content snapshot differs from the pre-run snapshot.

### Init constraints

- At most **8 documentation pages** unless the repository is clearly tiny.
- Do not document every source file. Cover architecture, workflows, domain concepts, data models, integrations, operations, tests, and extension points at the right level of detail.
- Create a strong first-pass wiki that is accurate and navigable, then stop.

---

## Update mode

**Inspect existing `openwiki/` before editing.**

### Workflow

1. Record a **content snapshot** of `openwiki/` (excluding `.last-update.json`) before editing.
2. Read `openwiki/.last-update.json` if it exists.
3. Gather git context scoped to changes since the last successful run.
4. Build a **docs impact plan**:

   ```
   source change → docs affected → edit needed → why
   ```

5. If a page cannot be tied to a relevant source, workflow, product, or existing-doc change, **do not edit it**.
6. Optionally delegate read-only workers for changed domains.
7. Write `openwiki/_plan.md` with planned surgical edits.
8. Apply only necessary edits per the impact plan.
9. Refresh agent instruction files only if the OpenWiki section is missing or semantically stale.
10. Delete `openwiki/_plan.md`.
11. Update `.last-update.json` **only if** the post-run content snapshot differs from the pre-run snapshot.

### Surgical edit rules

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
| More than 3 pages seem needed | Stop and reconsider before broad changes |

- Avoid touching `quickstart.md` unless top-level product behavior, setup, or navigation changed.

### No-op updates

If there are no relevant source, workflow, product, or existing-doc changes since the last successful run **and** the wiki is already accurate:

- **Do not edit files.**
- **Do not update** `.last-update.json`.
- Tell the user the wiki is already current.

Updates may be a no-op. This is correct behavior.

---

## Chat mode

- Answer the user's message directly.
- Do **not** create or update OpenWiki documentation unless the user explicitly asks.
- If the user asks to initialize or update the wiki, switch to init or update mode, or mention the optional OpenWiki CLI.

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

Run `openwiki --help` when possible. If unavailable, answer from the table and note help could not be verified live.

---

## Git context commands

Run from the repository root at the start of init/update.

### Always

```bash
git status --short
git rev-parse HEAD
git diff --name-status HEAD
```

### Init, or update with no prior metadata

```bash
git log --max-count=20 --name-status --oneline
```

### Update — when `.last-update.json` has `gitHead`

```bash
git log <gitHead>..HEAD --name-status --oneline
```

### Update — when no `gitHead` but `updatedAt` exists

```bash
git log --since "<updatedAt ISO timestamp>" --name-status --oneline
```

### Update — no prior metadata

Emit: "No prior OpenWiki update timestamp was found." Then use the init-style recent-20 log.

Use helper scripts from the **installed skill directory** with **cwd set to the target repository**:

```bash
cd /path/to/target-repo
bash /path/to/installed-skill/scripts/gather-git-context.sh init
bash /path/to/installed-skill/scripts/gather-git-context.sh update
```

Or run equivalent commands below manually.
