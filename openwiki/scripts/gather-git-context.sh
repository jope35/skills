#!/usr/bin/env bash
# Gather git context for OpenWiki init/update runs.
#
# Run from the TARGET REPOSITORY root. Pass the script path from the
# installed skill directory, for example:
#   cd /path/to/target-repo
#   bash /path/to/installed-skill/scripts/gather-git-context.sh init
#   bash /path/to/installed-skill/scripts/gather-git-context.sh update
#
# metadata-file defaults to openwiki/.last-update.json (relative to cwd)

set -euo pipefail

MODE="${1:-}"
METADATA_FILE="${2:-openwiki/.last-update.json}"

if [[ "$MODE" != "init" && "$MODE" != "update" ]]; then
  echo "Usage: $0 <init|update> [metadata-file]" >&2
  echo "Run with cwd set to the target repository root." >&2
  exit 1
fi

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

section() {
  local title="$1"
  shift
  echo "$title"
  echo '```'
  "$@" 2>/dev/null || true
  echo '```'
  echo
}

section "git status --short" git status --short
section "git rev-parse HEAD" git rev-parse HEAD

if [[ "$MODE" == "init" ]]; then
  section "git log --max-count=20 --name-status --oneline" \
    git log --max-count=20 --name-status --oneline
else
  if [[ -f "$METADATA_FILE" ]]; then
    GIT_HEAD="$(json_field "$METADATA_FILE" gitHead)"
    UPDATED_AT="$(json_field "$METADATA_FILE" updatedAt)"

    if [[ -n "$GIT_HEAD" ]]; then
      section "git log ${GIT_HEAD}..HEAD --name-status --oneline" \
        git log "${GIT_HEAD}..HEAD" --name-status --oneline
    elif [[ -n "$UPDATED_AT" ]]; then
      section "git log --since ${UPDATED_AT} --name-status --oneline" \
        git log --since "$UPDATED_AT" --name-status --oneline
    else
      echo "No prior OpenWiki update metadata was found."
      echo
      section "git log --max-count=20 --name-status --oneline" \
        git log --max-count=20 --name-status --oneline
    fi
  else
    echo "No prior OpenWiki update metadata was found."
    echo
    section "git log --max-count=20 --name-status --oneline" \
      git log --max-count=20 --name-status --oneline
  fi
fi

section "git diff --name-status HEAD" git diff --name-status HEAD
