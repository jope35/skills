#!/usr/bin/env bash
# Gather compact git context for OpenWiki init/update runs.
#
# Token-minimized (RTK-inspired): short labels, porcelain status, one-line
# commits with capped file lists, and name-status worktree diffs. In update
# mode, also emits an upstream-style pre-noop assessment.
#
# Run from the TARGET REPOSITORY root:
#   cd /path/to/target-repo
#   bash /path/to/installed-skill/scripts/gather-git-context.sh init
#   bash /path/to/installed-skill/scripts/gather-git-context.sh update
#
# Optional env:
#   OPENWIKI_GIT_LOG_LIMIT_INIT=15
#   OPENWIKI_GIT_LOG_LIMIT_UPDATE=25
#   OPENWIKI_GIT_MAX_FILES_PER_COMMIT=10
#   OPENWIKI_GIT_MAX_SUBJECT=100

set -euo pipefail

MODE="${1:-}"
METADATA_FILE="${2:-openwiki/.last-update.json}"

if [[ "$MODE" != "init" && "$MODE" != "update" ]]; then
  echo "Usage: $0 <init|update> [metadata-file]" >&2
  echo "Run with cwd set to the target repository root." >&2
  exit 1
fi

git_out() {
  git --no-pager "$@" 2>/dev/null || true
}

json_field() {
  local file="$1"
  local field="$2"

  if [[ ! -f "$file" ]]; then
    return 0
  fi

  python3 -c "
import json
import sys

try:
    with open(sys.argv[1], encoding='utf-8') as handle:
        data = json.load(handle)
    value = data.get(sys.argv[2], '')
    if isinstance(value, str):
        print(value)
except Exception:
    pass
" "$file" "$field" 2>/dev/null || true
}

LOG_LIMIT_INIT="${OPENWIKI_GIT_LOG_LIMIT_INIT:-15}"
LOG_LIMIT_UPDATE="${OPENWIKI_GIT_LOG_LIMIT_UPDATE:-25}"
MAX_FILES_PER_COMMIT="${OPENWIKI_GIT_MAX_FILES_PER_COMMIT:-10}"
MAX_SUBJECT="${OPENWIKI_GIT_MAX_SUBJECT:-100}"

HEAD="$(git_out rev-parse HEAD)"
STATUS="$(git_out status --porcelain=v1 -b --untracked-files=all)"
DIFF="$(git_out diff --name-status HEAD)"
STAGED="$(git_out diff --cached --name-status HEAD)"

LOG_ARGS=()
LOG_LABEL="recent"
PRIOR="none"
GIT_HEAD=""
UPDATED_AT=""

if [[ "$MODE" == "init" ]]; then
  LOG_ARGS=(--max-count="$LOG_LIMIT_INIT")
else
  if [[ -f "$METADATA_FILE" ]]; then
    GIT_HEAD="$(json_field "$METADATA_FILE" gitHead)"
    UPDATED_AT="$(json_field "$METADATA_FILE" updatedAt)"

    if [[ -n "$GIT_HEAD" ]]; then
      LOG_ARGS=("${GIT_HEAD}..HEAD")
      LOG_LABEL="since ${GIT_HEAD:0:7}"
      PRIOR="$GIT_HEAD"
    elif [[ -n "$UPDATED_AT" ]]; then
      LOG_ARGS=(--since "$UPDATED_AT")
      LOG_LABEL="since ${UPDATED_AT}"
      PRIOR="$UPDATED_AT"
    else
      LOG_ARGS=(--max-count="$LOG_LIMIT_INIT")
      LOG_LABEL="recent (no prior metadata)"
    fi
  else
    LOG_ARGS=(--max-count="$LOG_LIMIT_INIT")
    LOG_LABEL="recent (no prior metadata)"
  fi
fi

LOG="$(git_out log "${LOG_ARGS[@]}" --name-status --pretty=format:'---COMMIT---%n%h %s (%ar) <%an>')"
CHANGED_PATHS=""
if [[ "$MODE" == "update" && -n "$GIT_HEAD" && -n "$HEAD" && "$GIT_HEAD" != "$HEAD" ]]; then
  CHANGED_PATHS="$(git_out diff --name-only "${GIT_HEAD}..HEAD")"
fi

export MODE HEAD STATUS DIFF STAGED LOG LOG_LABEL PRIOR GIT_HEAD CHANGED_PATHS
export LOG_LIMIT_UPDATE MAX_FILES_PER_COMMIT MAX_SUBJECT

python3 <<'PY'
import os

mode = os.environ["MODE"]
head = os.environ.get("HEAD", "").strip()
status = os.environ.get("STATUS", "")
diff = os.environ.get("DIFF", "")
staged = os.environ.get("STAGED", "")
log = os.environ.get("LOG", "")
log_label = os.environ.get("LOG_LABEL", "recent")
prior = os.environ.get("PRIOR", "none")
git_head = os.environ.get("GIT_HEAD", "").strip()
changed_paths = os.environ.get("CHANGED_PATHS", "")
log_limit_update = int(os.environ.get("LOG_LIMIT_UPDATE", "25"))
max_files = int(os.environ.get("MAX_FILES_PER_COMMIT", "10"))
max_subject = int(os.environ.get("MAX_SUBJECT", "100"))

METADATA_BASENAME = ".last-update.json"


def emit(label: str, body: str) -> None:
    body = body.strip()
    if not body:
        return
    print(f"{label}\n{body}")


def truncate(text: str, width: int) -> str:
    text = text.strip()
    if len(text) <= width:
        return text
    return text[: width - 3] + "..."


def status_path(line: str) -> str:
    if len(line) < 4:
        return line.strip()
    path = line[3:].strip()
    if " -> " in path:
        path = path.split(" -> ", 1)[1]
    return path.replace("\\", "/")


def is_metadata_status_line(line: str) -> bool:
    path = status_path(line)
    return path == f"openwiki/{METADATA_BASENAME}" or path.endswith(
        f"/{METADATA_BASENAME}"
    )


def is_openwiki_path(path: str) -> bool:
    normalized = path.replace("\\", "/").lstrip("./")
    return normalized == "openwiki" or normalized.startswith("openwiki/")


def format_status(porcelain: str) -> str:
    lines = [line for line in porcelain.splitlines() if line.strip()]
    if not lines:
        return "clean"

    out: list[str] = []
    if lines[0].startswith("##"):
        out.append(f"* {lines[0][3:].strip()}")
        file_lines = lines[1:]
    else:
        file_lines = lines

    # Match upstream noop filtering: metadata churn is not meaningful worktree noise.
    file_lines = [line for line in file_lines if not is_metadata_status_line(line)]

    if not file_lines:
        out.append("clean — nothing to commit")
        return "\n".join(out)

    grouped: dict[str, list[str]] = {}
    for line in file_lines:
        if len(line) < 4:
            continue
        grouped.setdefault(line[:2], []).append(line[3:])

    for xy in sorted(grouped):
        paths = grouped[xy]
        if len(paths) == 1:
            out.append(f"{xy} {paths[0]}")
            continue

        by_dir: dict[str, int] = {}
        for path in paths:
            by_dir[path.split("/", 1)[0]] = by_dir.get(path.split("/", 1)[0], 0) + 1

        if len(by_dir) == 1 and len(paths) > 2:
            only = next(iter(by_dir))
            out.append(f"{xy} {only}/ ({len(paths)} files)")
            continue

        shown = paths[:max_files]
        out.extend(f"{xy} {path}" for path in shown)
        extra = len(paths) - len(shown)
        if extra > 0:
            out.append(f"{xy} ... (+{extra} more)")

    return "\n".join(out)


def summarize_name_status(block: str) -> str:
    lines = [line for line in block.splitlines() if line.strip()]
    if not lines:
        return ""

    out: list[str] = []
    for line in lines:
        parts = line.split("\t", 1)
        if len(parts) != 2:
            continue
        status, path = parts
        out.append(f"{status} {path}")

    if len(out) > max_files:
        kept = out[:max_files]
        kept.append(f"... (+{len(out) - max_files} more)")
        return "\n".join(kept)
    return "\n".join(out)


def format_log(raw: str) -> str:
    if not raw.strip():
        return "(no commits)"

    chunks = [chunk.strip() for chunk in raw.split("---COMMIT---") if chunk.strip()]
    tail_note = ""
    if mode == "update" and len(chunks) > log_limit_update:
        omitted = len(chunks) - log_limit_update
        chunks = chunks[:log_limit_update]
        tail_note = f"... (+{omitted} older commits omitted)"

    entries: list[str] = []
    for chunk in chunks:
        lines = chunk.splitlines()
        if not lines:
            continue
        header = truncate(lines[0], max_subject)
        files = summarize_name_status("\n".join(lines[1:]))
        entries.append(f"{header}\n{files}" if files else header)

    body = "\n\n".join(entries)
    if tail_note:
        body = f"{body}\n{tail_note}" if body else tail_note
    return body or "(no commits)"


def filter_metadata_name_status(block: str) -> str:
    kept: list[str] = []
    metadata_suffix = f"openwiki/{METADATA_BASENAME}"
    for line in block.splitlines():
        if not line.strip():
            continue
        parts = line.split("\t", 1)
        if len(parts) == 2:
            path = parts[1].replace("\\", "/")
            if path == metadata_suffix or path.endswith(f"/{metadata_suffix}"):
                continue
        kept.append(line)
    return "\n".join(kept)


def format_worktree(diff_text: str, staged_text: str) -> str:
    parts: list[str] = []
    staged_summary = summarize_name_status(filter_metadata_name_status(staged_text))
    diff_summary = summarize_name_status(filter_metadata_name_status(diff_text))
    if staged_summary:
        parts.append(f"staged\n{staged_summary}")
    if diff_summary:
        parts.append(f"unstaged\n{diff_summary}")
    return "\n".join(parts) if parts else "clean"


def assess_pre_noop() -> str:
    """Mirror upstream getUpdateNoopStatus for portable harnesses."""
    if not git_head:
        return "run — missing previous update git head"

    if not head:
        return "run — missing current git head"

    status_lines = [
        line
        for line in status.splitlines()
        if line.strip() and not line.startswith("##") and not is_metadata_status_line(line)
    ]
    if status_lines:
        return "run — worktree has changes"

    if head == git_head:
        return "skip — head unchanged and worktree clean"

    paths = [path.strip() for path in changed_paths.splitlines() if path.strip()]
    if not paths:
        return "skip — no non-openwiki commits since last update"

    if any(not is_openwiki_path(path) for path in paths):
        return "run — non-openwiki commits since last update"

    return "skip — only openwiki/ commits since last update"


print(f"openwiki git ctx | mode={mode}")
emit("head", head or "(unknown)")
emit("prior", prior)
if mode == "update":
    emit("pre-noop", assess_pre_noop())
emit("status", format_status(status))
emit(f"log {log_label}", format_log(log))
emit("worktree", format_worktree(diff, staged))
PY
