#!/usr/bin/env bash
set -euo pipefail

WORK_SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$WORK_SKILL_DIR/scripts/lib.sh"

usage() {
  cat <<'EOF'
Usage: work-cleanup.sh [issue-id|branch|path]

Removes only worktrees whose GitHub issue is closed. Local branches are deleted
with git branch -d only when the associated PR is merged.
EOF
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  usage
  exit 0
fi

query="${1:-}"

work_init
targets="$(work_find_worktree "$query")"
if [ -z "$targets" ]; then
  count=0
else
  count="$(wc -l <<<"$targets" | tr -d ' ')"
fi

if [ "$count" = "0" ]; then
  echo "No cleanup candidates found for: ${query:-<all>}" >&2
  exit 1
fi

while IFS= read -r worktree_path; do
  [ -n "$worktree_path" ] || continue
  repo="$(work_repo_for_worktree "$worktree_path")"
  branch="$(git -C "$worktree_path" branch --show-current 2>/dev/null || true)"
  issue="$(work_issue_from_branch "$branch" 2>/dev/null || true)"

  if [ -z "$issue" ]; then
    echo "KEEP $worktree_path: branch does not contain an issue id"
    continue
  fi

  issue_json="$(gh api "repos/$ORG/$repo/issues/$issue")" || {
    echo "KEEP $worktree_path: could not verify issue state"
    continue
  }
  issue_state="$(jq -r '.state // empty' <<<"$issue_json")"

  if [ "$issue_state" != "closed" ]; then
    echo "KEEP $worktree_path: issue #$issue is $issue_state"
    continue
  fi

  repo_dir="$(work_primary_repo_dir "$repo" "$worktree_path")"
  if git -C "$repo_dir" worktree remove "$worktree_path"; then
    echo "REMOVED $worktree_path: issue #$issue is closed"
  else
    echo "KEEP $worktree_path: git worktree remove failed"
    continue
  fi

  if work_branch_pr_merged "$repo" "$branch"; then
    if git -C "$repo_dir" branch -d "$branch"; then
      echo "DELETED branch $branch: merged PR found"
    else
      echo "KEPT branch $branch: git branch -d refused"
    fi
  else
    echo "KEPT branch $branch: no merged PR found"
  fi
done <<<"$targets"

while IFS= read -r repo_dir; do
  git -C "$repo_dir" worktree prune
done < <(work_repo_dirs)
