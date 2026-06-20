#!/usr/bin/env bash
set -euo pipefail

WORK_SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$WORK_SKILL_DIR/scripts/lib.sh"

usage() {
  cat <<'EOF'
Usage: work-sync.sh [issue-id|branch|path] [--rebase|--merge]

Fetches the remote base branch and syncs a worktree. Default is rebase.
When an open PR exists, the script tries a fast-forward merge first and asks
for explicit --merge before creating a merge commit.
EOF
}

query=""
strategy=""
for arg in "$@"; do
  case "$arg" in
    --help|-h)
      usage
      exit 0
      ;;
    --rebase|--merge)
      strategy="${arg#--}"
      ;;
    *)
      if [ -z "$query" ]; then
        query="$arg"
      else
        echo "Unexpected argument: $arg" >&2
        usage >&2
        exit 2
      fi
      ;;
  esac
done

work_init

if [ -n "$query" ]; then
  matches="$(work_find_worktree "$query")"
  if [ -z "$matches" ]; then
    count=0
  else
    count="$(wc -l <<<"$matches" | tr -d ' ')"
  fi
  [ "$count" = "1" ] || { echo "Expected exactly one matching worktree, found $count." >&2; printf '%s\n' "$matches" >&2; exit 2; }
  target="$matches"
else
  target="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  [ -n "$target" ] || { echo "Not in a git worktree; pass issue, branch, or path." >&2; exit 1; }
fi

repo="$(work_repo_for_worktree "$target")"
branch="$(git -C "$target" branch --show-current)"
repo_dir="$(work_primary_repo_dir "$repo" "$target")"
base="$(work_base_ref "$repo_dir")"
stashed=0

work_fetch_base "$repo_dir"

if [ -n "$(git -C "$target" status --porcelain)" ]; then
  if git -C "$target" stash push -u -m "work sync auto-stash" >/dev/null; then
    stashed=1
  fi
fi

if [ -z "$strategy" ]; then
  if work_branch_has_open_pr "$repo" "$branch"; then
    strategy="merge-ff-only"
  else
    strategy="rebase"
  fi
fi

set +e
case "$strategy" in
  rebase)
    git -C "$target" rebase "$base"
    sync_status=$?
    ;;
  merge)
    git -C "$target" merge --no-edit "$base"
    sync_status=$?
    ;;
  merge-ff-only)
    git -C "$target" merge --ff-only "$base"
    sync_status=$?
    if [ "$sync_status" -ne 0 ]; then
      echo "Open PR detected, but fast-forward merge was not possible." >&2
      echo "Resolve manually or rerun with --merge if a merge commit is intended." >&2
    fi
    ;;
  *)
    echo "Unknown sync strategy: $strategy" >&2
    sync_status=2
    ;;
esac
set -e

if [ "$sync_status" -eq 0 ] && [ "$stashed" = "1" ]; then
  git -C "$target" stash pop
elif [ "$stashed" = "1" ]; then
  echo "Local changes remain in git stash because sync did not finish cleanly." >&2
fi

exit "$sync_status"
