#!/usr/bin/env bash
set -euo pipefail

WORK_SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$WORK_SKILL_DIR/scripts/lib.sh"

usage() {
  cat <<'EOF'
Usage: work-list.sh

Lists work-managed worktrees with issue, PR, dirty, and ahead/behind state.
EOF
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  usage
  exit 0
fi

work_init

printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "REPO" "BRANCH" "ISSUE" "PR" "DIRTY" "AHEAD/BEHIND" "PATH"

while IFS= read -r worktree_path; do
  git -C "$worktree_path" rev-parse --show-toplevel >/dev/null 2>&1 || continue

  repo="$(work_repo_for_worktree "$worktree_path")"
  branch="$(git -C "$worktree_path" branch --show-current 2>/dev/null || true)"
  issue="$(work_issue_from_branch "$branch" 2>/dev/null || echo "?")"
  issue_state="?"
  if [ "$issue" != "?" ]; then
    issue_state="$(gh api "repos/$ORG/$repo/issues/$issue" --jq '.state // "?"' 2>/dev/null || echo "issue-error")"
  fi
  dirty="$(git -C "$worktree_path" status --porcelain | wc -l | tr -d ' ')"
  pr="$(work_branch_pr_summary "$repo" "$branch" 2>/dev/null || echo "pr-error")"
  repo_dir="$(work_primary_repo_dir "$repo" "$worktree_path")"
  base="$(work_base_ref "$repo_dir")"
  ahead_behind="$(git -C "$worktree_path" rev-list --left-right --count "$base...HEAD" 2>/dev/null || echo "?")"

  printf '%s\t%s\t#%s %s\t%s\t%s\t%s\t%s\n' "$repo" "$branch" "$issue" "$issue_state" "$pr" "$dirty" "$ahead_behind" "$worktree_path"
done < <(work_worktree_dirs)
