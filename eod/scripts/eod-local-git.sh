#!/usr/bin/env bash
set -euo pipefail

json=false
if [ "${1:-}" = "--json" ]; then
  json=true
fi

tz="${EOD_TZ:-${TZ:-UTC}}"
export TZ="$tz"

root="${EOD_DEV_ROOT:-$HOME/projects}"
today="$(date +%Y-%m-%d)"

emit_json_status() {
  status="$1"
  if command -v jq >/dev/null 2>&1; then
    jq -n \
      --arg timezone "$tz" \
      --arg date "$today" \
      --arg dev_root "$root" \
      --arg status "$status" \
      '{timezone:$timezone,date:$date,dev_root:$dev_root,status:$status,repos:[]}'
  else
    printf '{"timezone":"%s","date":"%s","dev_root":"%s","status":"%s","repos":[]}\n' "$tz" "$today" "$root" "$status"
  fi
}

if [ "$json" = true ] && ! command -v jq >/dev/null 2>&1; then
  emit_json_status "missing-jq"
  exit 0
fi

if [ "$json" = false ]; then
  printf 'timezone=%s\n' "$tz"
  printf 'date=%s\n' "$today"
  printf 'dev_root=%s\n' "$root"
fi

if [ ! -d "$root" ]; then
  if [ "$json" = true ]; then
    emit_json_status "no-dev-root"
  else
    printf 'status=no-dev-root\n'
  fi
  exit 0
fi

tmp_git_paths="$(mktemp)"
tmp_repos="$(mktemp)"
tmp_repo_json="$(mktemp)"
trap 'rm -f "$tmp_git_paths" "$tmp_repos" "$tmp_repo_json"' EXIT

find "$root" \
  \( -path '*/node_modules/*' -o -path '*/.next/*' -o -path '*/dist/*' -o -path '*/build/*' \) -prune \
  -o -name .git -print > "$tmp_git_paths"

while IFS= read -r git_path; do
  repo_dir="$(dirname "$git_path")"
  if git -C "$repo_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "$repo_dir" rev-parse --show-toplevel
  fi
done < "$tmp_git_paths" | sort -u > "$tmp_repos"

if [ ! -s "$tmp_repos" ]; then
  if [ "$json" = true ]; then
    emit_json_status "no-git-repos"
  else
    printf 'status=no-git-repos\n'
  fi
  exit 0
fi

while IFS= read -r repo; do
  branch="$(git -C "$repo" branch --show-current 2>/dev/null || true)"
  remote="$(git -C "$repo" remote get-url origin 2>/dev/null || true)"
  status_text="$(git -C "$repo" status --short 2>/dev/null || true)"
  status_count="$(printf '%s\n' "$status_text" | sed '/^$/d' | wc -l | tr -d ' ')"
  author_email="$(git -C "$repo" config user.email 2>/dev/null || true)"
  upstream="none"
  behind=""
  ahead=""

  if upstream_value="$(git -C "$repo" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null)"; then
    upstream="$upstream_value"
    ahead_behind="$(git -C "$repo" rev-list --left-right --count "$upstream"...HEAD 2>/dev/null || true)"
    behind="$(printf '%s\n' "$ahead_behind" | awk '{print $1}')"
    ahead="$(printf '%s\n' "$ahead_behind" | awk '{print $2}')"
  fi

  commits=""
  if [ -n "$author_email" ]; then
    commits="$(git -C "$repo" log --since="$today 00:00" --author="$author_email" --oneline -n 30 2>/dev/null || true)"
  fi

  if [ "$json" = true ]; then
    status_json="$(printf '%s\n' "$status_text" | sed '/^$/d' | jq -Rsc 'split("\n") | map(select(length > 0))')"
    commits_json="$(printf '%s\n' "$commits" | sed '/^$/d' | jq -Rsc 'split("\n") | map(select(length > 0))')"
    jq -n \
      --arg repo "$repo" \
      --arg branch "${branch:-detached-or-empty}" \
      --arg remote "${remote:-none}" \
      --arg status_count "$status_count" \
      --arg upstream "$upstream" \
      --arg behind "$behind" \
      --arg ahead "$ahead" \
      --argjson status_files "$status_json" \
      --argjson commits_authored_today "$commits_json" \
      '{repo:$repo,branch:$branch,remote:$remote,status_count:($status_count|tonumber),status_files:$status_files,upstream:$upstream,behind:($behind|tonumber? // null),ahead:($ahead|tonumber? // null),commits_authored_today:$commits_authored_today}' \
      >> "$tmp_repo_json"
    continue
  fi

  printf '\nrepo=%s\n' "$repo"
  printf 'branch=%s\n' "${branch:-detached-or-empty}"
  printf 'remote=%s\n' "${remote:-none}"
  printf 'status_count=%s\n' "$status_count"

  if [ "$status_count" != "0" ]; then
    printf 'status_files:\n'
    printf '%s\n' "$status_text" | sed -n '1,40p'
  fi

  printf 'upstream=%s\n' "$upstream"
  if [ "$upstream" != "none" ]; then
    printf 'behind_ahead=%s %s\n' "${behind:-unknown}" "${ahead:-unknown}"
  fi

  if [ -n "$commits" ]; then
    printf 'commits_authored_today:\n'
    printf '%s\n' "$commits"
  fi
done < "$tmp_repos"

if [ "$json" = true ]; then
  jq -s \
    --arg timezone "$tz" \
    --arg date "$today" \
    --arg dev_root "$root" \
    --arg status "ok" \
    '{timezone:$timezone,date:$date,dev_root:$dev_root,status:$status,repos:.}' \
    "$tmp_repo_json"
fi
