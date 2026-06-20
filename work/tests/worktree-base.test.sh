#!/usr/bin/env bash
set -euo pipefail

WORK_SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$WORK_SKILL_DIR/scripts/lib.sh"

tmp="$(mktemp -d)"
tmp="$(cd "$tmp" && pwd -P)"
trap 'rm -rf "$tmp"' EXIT

remote="$tmp/remote.git"
seed="$tmp/seed"
repo="$tmp/repo"
worktree="$tmp/worktree"
existing_branch_worktree="$tmp/existing-branch-worktree"
existing_path_worktree="$tmp/existing-path-worktree"

git init --bare --initial-branch=main "$remote" >/dev/null
git clone "$remote" "$seed" >/dev/null 2>&1
git -C "$seed" config user.email "test@example.com"
git -C "$seed" config user.name "Test User"

printf 'local base\n' > "$seed/file.txt"
git -C "$seed" add file.txt
git -C "$seed" commit -m "local base" >/dev/null
git -C "$seed" push origin main >/dev/null 2>&1
local_commit="$(git -C "$seed" rev-parse HEAD)"

git clone "$remote" "$repo" >/dev/null 2>&1

printf 'remote base\n' > "$seed/file.txt"
git -C "$seed" commit -am "remote base" >/dev/null
git -C "$seed" push origin main >/dev/null 2>&1
remote_commit="$(git -C "$seed" rev-parse HEAD)"

if [ "$(git -C "$repo" rev-parse main)" != "$local_commit" ]; then
  echo "test setup failed: local main should be stale before worktree creation" >&2
  exit 1
fi

work_create_worktree "$repo" "$worktree" "feat/123-test-remote-base" >/dev/null 2>&1

actual="$(git -C "$worktree" rev-parse HEAD)"

if [ "$actual" != "$remote_commit" ]; then
  printf 'expected branch from remote: %s\nactual:              %s\n' "$remote_commit" "$actual" >&2
  exit 1
fi

git -C "$repo" branch "feat/124-existing-branch" "$remote_commit"
work_create_worktree "$repo" "$existing_branch_worktree" "feat/124-existing-branch" >/dev/null 2>&1

if [ "$(git -C "$existing_branch_worktree" rev-parse --abbrev-ref HEAD)" != "feat/124-existing-branch" ]; then
  echo "expected existing branch to be reused for worktree creation" >&2
  exit 1
fi

first_reuse="$(work_create_worktree "$repo" "$existing_path_worktree" "feat/125-existing-path" 2>/dev/null)"
git -C "$repo" remote set-url origin "$tmp/missing.git"
second_reuse="$(work_create_worktree "$repo" "$existing_path_worktree" "feat/125-existing-path" 2>/dev/null)"

if [ "$first_reuse" != "$second_reuse" ]; then
  printf 'expected existing path reuse to return same path\nfirst:  %s\nsecond: %s\n' "$first_reuse" "$second_reuse" >&2
  exit 1
fi

git -C "$repo" branch "feat/126-offline-existing-branch" "$remote_commit"
work_create_worktree "$repo" "$tmp/offline-existing-branch-worktree" "feat/126-offline-existing-branch" >/dev/null 2>&1

if [ "$(git -C "$tmp/offline-existing-branch-worktree" rev-parse --abbrev-ref HEAD)" != "feat/126-offline-existing-branch" ]; then
  echo "expected existing branch to be reused without fetching" >&2
  exit 1
fi
