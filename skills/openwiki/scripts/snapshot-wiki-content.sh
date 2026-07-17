#!/usr/bin/env bash
# Compute a SHA-256 fingerprint of all openwiki/ content except .last-update.json.
# Mirrors upstream OpenWiki content-snapshot semantics for no-op detection.
#
# Invoke with a skill-root-relative path (Agent Skills convention). Either:
#   OPENWIKI_TARGET_REPO=/path/to/target-repo bash scripts/snapshot-wiki-content.sh
# or run with cwd already set to the target repository:
#   cd /path/to/target-repo && bash <skill-root>/scripts/snapshot-wiki-content.sh
#
# Optional first arg: wiki directory (default: openwiki).
# Optional env: OPENWIKI_TARGET_REPO=/path/to/target-repo
#
# Print the hex digest to stdout. Compare before and after init/update runs.
# If identical, do not write openwiki/.last-update.json.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/snapshot-wiki-content.sh [wiki-dir]

Compute a SHA-256 fingerprint of wiki content excluding .last-update.json.

Arguments:
  wiki-dir   Wiki directory relative to the target repo (default: openwiki)

Environment:
  OPENWIKI_TARGET_REPO   Target repository root (optional if cwd is the repo)

Examples:
  OPENWIKI_TARGET_REPO=/path/to/repo bash scripts/snapshot-wiki-content.sh
  OPENWIKI_TARGET_REPO=/path/to/repo bash scripts/snapshot-wiki-content.sh openwiki
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ -n "${OPENWIKI_TARGET_REPO:-}" ]]; then
  if [[ ! -d "$OPENWIKI_TARGET_REPO" ]]; then
    echo "Error: OPENWIKI_TARGET_REPO is not a directory: $OPENWIKI_TARGET_REPO" >&2
    exit 1
  fi
  cd "$OPENWIKI_TARGET_REPO"
fi

WIKI_DIR="${1:-openwiki}"
METADATA_BASENAME=".last-update.json"

if [[ ! -d "$WIKI_DIR" ]]; then
  # Empty wiki: stable fingerprint for "no content yet"
  printf '%s' "missing" | sha256sum | awk '{print $1}'
  exit 0
fi

{
  while IFS= read -r -d '' path; do
    relative="${path#./}"
    if [[ "$(basename "$path")" == "$METADATA_BASENAME" ]]; then
      continue
    fi
    if [[ -d "$path" ]]; then
      printf 'dir:%s\0' "$relative"
    elif [[ -f "$path" ]]; then
      printf 'file:%s\0' "$relative"
      cat "$path"
      printf '\0'
    fi
  done < <(
    find "$WIKI_DIR" \( -type f -o -type d \) -print0 2>/dev/null \
      | LC_ALL=C sort -z
  )
} | sha256sum | awk '{print $1}'
