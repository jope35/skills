#!/usr/bin/env bash
# Gather compact git context for OpenWiki init/update runs.
#
# Token-minimized (RTK-inspired): short labels, porcelain status, one-line
# commits with capped file lists, and name-status worktree diffs. In update
# mode, also emits an upstream-style pre-noop assessment.
#
# Pure bash — no Python required.
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
METADATA_BASENAME=".last-update.json"

if [[ "$MODE" != "init" && "$MODE" != "update" ]]; then
  echo "Usage: $0 <init|update> [metadata-file]" >&2
  echo "Run with cwd set to the target repository root." >&2
  exit 1
fi

LOG_LIMIT_INIT="${OPENWIKI_GIT_LOG_LIMIT_INIT:-15}"
LOG_LIMIT_UPDATE="${OPENWIKI_GIT_LOG_LIMIT_UPDATE:-25}"
MAX_FILES_PER_COMMIT="${OPENWIKI_GIT_MAX_FILES_PER_COMMIT:-10}"
MAX_SUBJECT="${OPENWIKI_GIT_MAX_SUBJECT:-100}"

git_out() {
  git --no-pager "$@" 2>/dev/null || true
}

# Extract a top-level JSON string field without Python.
# Accepts only simple "key": "value" string fields.
json_string_field() {
  local file="$1"
  local field="$2"
  local line

  if [[ ! -f "$file" ]]; then
    return 0
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ \"${field}\"[[:space:]]*:[[:space:]]*\"([^\"]*)\" ]]; then
      printf '%s\n' "${BASH_REMATCH[1]}"
      return 0
    fi
  done <"$file"
}

emit() {
  local label="$1"
  local body="$2"

  body="${body#"${body%%[![:space:]]*}"}"
  body="${body%"${body##*[![:space:]]}"}"
  [[ -z "$body" ]] && return 0
  printf '%s\n%s\n' "$label" "$body"
}

truncate_text() {
  local text="$1"
  local width="$2"

  if (( ${#text} <= width )); then
    printf '%s' "$text"
  else
    printf '%s...' "${text:0:$((width - 3))}"
  fi
}

status_path() {
  local line="$1"
  local path

  if (( ${#line} < 4 )); then
    printf '%s' "${line#"${line%%[![:space:]]*}"}"
    return 0
  fi

  path="${line:3}"
  path="${path#"${path%%[![:space:]]*}"}"
  path="${path//\\//}"
  if [[ "$path" == *" -> "* ]]; then
    path="${path##* -> }"
  fi
  printf '%s' "$path"
}

is_metadata_path() {
  local path="$1"
  path="${path//\\//}"
  [[ "$path" == "openwiki/${METADATA_BASENAME}" || "$path" == */"${METADATA_BASENAME}" ]]
}

is_metadata_status_line() {
  is_metadata_path "$(status_path "$1")"
}

is_openwiki_path() {
  local path="$1"
  path="${path//\\//}"
  path="${path#./}"
  [[ "$path" == "openwiki" || "$path" == openwiki/* ]]
}

format_status() {
  local porcelain="$1"
  local line branch xy path top_dir shown extra
  local -a lines=() file_lines=() out=() keys=() paths=()
  local -A grouped=() by_dir=()

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "${line//[[:space:]]/}" ]] && continue
    lines+=("$line")
  done <<<"$porcelain"

  if (( ${#lines[@]} == 0 )); then
    printf 'clean'
    return 0
  fi

  if [[ "${lines[0]}" == \#\#* ]]; then
    branch="${lines[0]:3}"
    branch="${branch#"${branch%%[![:space:]]*}"}"
    out+=("* ${branch}")
    file_lines=("${lines[@]:1}")
  else
    file_lines=("${lines[@]}")
  fi

  local -a filtered=()
  for line in "${file_lines[@]+"${file_lines[@]}"}"; do
    is_metadata_status_line "$line" && continue
    filtered+=("$line")
  done
  file_lines=("${filtered[@]+"${filtered[@]}"}")

  if (( ${#file_lines[@]} == 0 )); then
    out+=("clean — nothing to commit")
    printf '%s\n' "${out[@]}"
    return 0
  fi

  for line in "${file_lines[@]}"; do
    (( ${#line} < 4 )) && continue
    xy="${line:0:2}"
    path="${line:3}"
    if [[ -z "${grouped[$xy]+x}" ]]; then
      keys+=("$xy")
      grouped["$xy"]="$path"
    else
      grouped["$xy"]+=$'\n'"$path"
    fi
  done

  local IFS=$'\n'
  # shellcheck disable=SC2207
  keys=($(printf '%s\n' "${keys[@]}" | LC_ALL=C sort))
  unset IFS

  for xy in "${keys[@]}"; do
    mapfile -t paths <<<"${grouped[$xy]}"
    if (( ${#paths[@]} == 1 )); then
      out+=("${xy} ${paths[0]}")
      continue
    fi

    by_dir=()
    for path in "${paths[@]}"; do
      top_dir="${path%%/*}"
      by_dir["$top_dir"]=$((${by_dir[$top_dir]:-0} + 1))
    done

    if (( ${#by_dir[@]} == 1 && ${#paths[@]} > 2 )); then
      for top_dir in "${!by_dir[@]}"; do
        out+=("${xy} ${top_dir}/ (${#paths[@]} files)")
      done
      continue
    fi

    shown=0
    for path in "${paths[@]}"; do
      if (( shown >= MAX_FILES_PER_COMMIT )); then
        break
      fi
      out+=("${xy} ${path}")
      shown=$((shown + 1))
    done
    extra=$((${#paths[@]} - shown))
    if (( extra > 0 )); then
      out+=("${xy} ... (+${extra} more)")
    fi
  done

  printf '%s\n' "${out[@]}"
}

summarize_name_status() {
  local block="$1"
  local line status path
  local -a out=()

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "${line//[[:space:]]/}" ]] && continue
    [[ "$line" != *$'\t'* ]] && continue
    status="${line%%$'\t'*}"
    path="${line#*$'\t'}"
    is_metadata_path "$path" && continue
    out+=("${status} ${path}")
  done <<<"$block"

  if (( ${#out[@]} == 0 )); then
    return 0
  fi

  if (( ${#out[@]} > MAX_FILES_PER_COMMIT )); then
    printf '%s\n' "${out[@]:0:MAX_FILES_PER_COMMIT}"
    printf '... (+%s more)' "$((${#out[@]} - MAX_FILES_PER_COMMIT))"
  else
    printf '%s\n' "${out[@]}"
  fi
}

format_log() {
  local raw="$1"
  local chunk header files body current="" i
  local -a chunks=() entries=()
  local omitted=0 line

  if [[ -z "${raw//[[:space:]]/}" ]]; then
    printf '(no commits)'
    return 0
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" == "---COMMIT---" ]]; then
      if [[ -n "${current//[[:space:]]/}" ]]; then
        chunks+=("$current")
      fi
      current=""
      continue
    fi
    if [[ -n "$current" ]]; then
      current+=$'\n'"$line"
    else
      current="$line"
    fi
  done <<<"$raw"

  if [[ -n "${current//[[:space:]]/}" ]]; then
    chunks+=("$current")
  fi

  if [[ "$MODE" == "update" && ${#chunks[@]} -gt LOG_LIMIT_UPDATE ]]; then
    omitted=$((${#chunks[@]} - LOG_LIMIT_UPDATE))
    chunks=("${chunks[@]:0:LOG_LIMIT_UPDATE}")
  fi

  for chunk in "${chunks[@]+"${chunks[@]}"}"; do
    header="$(printf '%s\n' "$chunk" | sed -n '1p')"
    [[ -z "$header" ]] && continue
    header="$(truncate_text "$header" "$MAX_SUBJECT")"
    files="$(summarize_name_status "$(printf '%s\n' "$chunk" | sed '1d')")"
    if [[ -n "$files" ]]; then
      entries+=("${header}"$'\n'"${files}")
    else
      entries+=("$header")
    fi
  done

  if (( ${#entries[@]} == 0 )); then
    printf '(no commits)'
    return 0
  fi

  body=""
  for i in "${!entries[@]}"; do
    if (( i > 0 )); then
      body+=$'\n\n'
    fi
    body+="${entries[$i]}"
  done
  printf '%s' "$body"
  if (( omitted > 0 )); then
    printf '\n... (+%s older commits omitted)' "$omitted"
  fi
}

format_worktree() {
  local diff_text="$1"
  local staged_text="$2"
  local staged_summary diff_summary
  local -a parts=()

  staged_summary="$(summarize_name_status "$staged_text")"
  diff_summary="$(summarize_name_status "$diff_text")"

  if [[ -n "$staged_summary" ]]; then
    parts+=("staged"$'\n'"$staged_summary")
  fi
  if [[ -n "$diff_summary" ]]; then
    parts+=("unstaged"$'\n'"$diff_summary")
  fi

  if (( ${#parts[@]} == 0 )); then
    printf 'clean'
  else
    printf '%s\n' "${parts[@]}"
  fi
}

assess_pre_noop() {
  local line path
  local -a status_lines=() paths=()

  if [[ -z "$GIT_HEAD" ]]; then
    printf 'run — missing previous update git head'
    return 0
  fi

  if [[ -z "$HEAD" ]]; then
    printf 'run — missing current git head'
    return 0
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "${line//[[:space:]]/}" ]] && continue
    [[ "$line" == \#\#* ]] && continue
    is_metadata_status_line "$line" && continue
    status_lines+=("$line")
  done <<<"$STATUS"

  if (( ${#status_lines[@]} > 0 )); then
    printf 'run — worktree has changes'
    return 0
  fi

  if [[ "$HEAD" == "$GIT_HEAD" ]]; then
    printf 'skip — head unchanged and worktree clean'
    return 0
  fi

  while IFS= read -r path || [[ -n "$path" ]]; do
    [[ -z "${path//[[:space:]]/}" ]] && continue
    paths+=("$path")
  done <<<"$CHANGED_PATHS"

  if (( ${#paths[@]} == 0 )); then
    printf 'skip — no non-openwiki commits since last update'
    return 0
  fi

  for path in "${paths[@]}"; do
    if ! is_openwiki_path "$path"; then
      printf 'run — non-openwiki commits since last update'
      return 0
    fi
  done

  printf 'skip — only openwiki/ commits since last update'
}

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
    GIT_HEAD="$(json_string_field "$METADATA_FILE" gitHead)"
    UPDATED_AT="$(json_string_field "$METADATA_FILE" updatedAt)"

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

printf 'openwiki git ctx | mode=%s\n' "$MODE"
emit "head" "${HEAD:-(unknown)}"
emit "prior" "$PRIOR"
if [[ "$MODE" == "update" ]]; then
  emit "pre-noop" "$(assess_pre_noop)"
fi
emit "status" "$(format_status "$STATUS")"
emit "log ${LOG_LABEL}" "$(format_log "$LOG")"
emit "worktree" "$(format_worktree "$DIFF" "$STAGED")"
