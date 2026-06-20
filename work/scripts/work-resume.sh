#!/usr/bin/env bash
set -euo pipefail

WORK_SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$WORK_SKILL_DIR/scripts/lib.sh"

usage() {
  cat <<'EOF'
Usage: work-resume.sh [issue-id|branch|path]

Finds an existing work-managed worktree. The script prints the target path
because a child process cannot cd the parent shell.
EOF
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  usage
  exit 0
fi

query="${1:-}"

work_init
matches="$(work_find_worktree "$query")"
if [ -z "$matches" ]; then
  count=0
else
  count="$(wc -l <<<"$matches" | tr -d ' ')"
fi

case "$count" in
  0)
    echo "No matching worktree found for: ${query:-<any>}" >&2
    exit 1
    ;;
  1)
    worktree_path="$matches"
    repo="$(work_repo_for_worktree "$worktree_path")"
    branch="$(git -C "$worktree_path" branch --show-current 2>/dev/null || true)"
    issue="$(work_issue_from_branch "$branch" 2>/dev/null || echo "?")"
    dirty="$(git -C "$worktree_path" status --porcelain | wc -l | tr -d ' ')"
    pr="$(work_branch_pr_summary "$repo" "$branch" 2>/dev/null || echo "pr-error")"

    printf 'Worktree: %s\n' "$worktree_path"
    printf 'Repo: %s\n' "$repo"
    printf 'Branch: %s\n' "$branch"
    printf 'Issue: %s\n' "$issue"
    printf 'PR: %s\n' "$pr"
    printf 'Dirty files: %s\n' "$dirty"
    ;;
  *)
    echo "Multiple matching worktrees found. Choose one:" >&2
    printf '%s\n' "$matches" >&2
    exit 2
    ;;
esac
