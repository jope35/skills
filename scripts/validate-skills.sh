#!/usr/bin/env bash
# Validate every Agent Skill package in this repository against the
# Agent Skills specification using skills-ref.
#
# Usage (from repository root):
#   bash scripts/validate-skills.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

mapfile -t skill_dirs < <(
  find . -type f -name 'SKILL.md' ! -path './.git/*' -printf '%h\n' | sort -u
)

if (( ${#skill_dirs[@]} == 0 )); then
  echo "No SKILL.md packages found" >&2
  exit 1
fi

failed=0
for dir in "${skill_dirs[@]}"; do
  echo "Validating ${dir}..."
  if ! npx --yes skills-ref validate "$dir"; then
    failed=1
  fi
done

if (( failed != 0 )); then
  echo "One or more skills failed Agent Skills specification validation." >&2
  exit 1
fi

echo "All ${#skill_dirs[@]} skill package(s) are valid."
