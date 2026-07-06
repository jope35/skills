#!/usr/bin/env bash
# Compute a SHA-256 fingerprint of openwiki/ content, excluding .last-update.json.
# Mirrors upstream OpenWiki content-snapshot semantics for no-op detection.
#
# Run from the TARGET REPOSITORY root. Pass the script path from the
# installed skill directory, for example:
#   cd /path/to/target-repo
#   bash /path/to/installed-skill/scripts/snapshot-wiki-content.sh
#   bash /path/to/installed-skill/scripts/snapshot-wiki-content.sh openwiki
#
# Print the hex digest to stdout. Compare before and after init/update runs.
# If identical, do not write openwiki/.last-update.json.

set -euo pipefail

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
