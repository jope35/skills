#!/usr/bin/env bash
# Gather git context for OpenWiki init/update runs.
# Usage:
#   ./gather-git-context.sh init
#   ./gather-git-context.sh update [metadata-file]
#
# metadata-file defaults to openwiki/.last-update.json

set -euo pipefail

MODE="${1:-}"
METADATA_FILE="${2:-openwiki/.last-update.json}"

if [[ "$MODE" != "init" && "$MODE" != "update" ]]; then
  echo "Usage: $0 <init|update> [metadata-file]" >&2
  exit 1
fi

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
    GIT_HEAD=$(python3 -c "
import json, sys
try:
    d = json.load(open('$METADATA_FILE'))
    print(d.get('gitHead', ''))
except Exception:
    print('')
" 2>/dev/null || echo "")

    UPDATED_AT=$(python3 -c "
import json, sys
try:
    d = json.load(open('$METADATA_FILE'))
    print(d.get('updatedAt', ''))
except Exception:
    print('')
" 2>/dev/null || echo "")

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
