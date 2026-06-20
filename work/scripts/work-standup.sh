#!/usr/bin/env bash
set -euo pipefail

WORK_SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$WORK_SKILL_DIR/scripts/lib.sh"

usage() {
  cat <<'EOF'
Usage: work-standup.sh

Summarizes recent local commits, active worktrees, and assigned open issues.
EOF
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  usage
  exit 0
fi

work_init

author_email="$(git config --global user.email 2>/dev/null || true)"

printf 'Yesterday / recent local commits:\n'
if [ -n "$author_email" ]; then
  while IFS= read -r repo_dir; do
    repo="$(basename "$repo_dir")"
    git -C "$repo_dir" log --since='36 hours ago' --author="$author_email" \
      --pretty=format:"- [$repo] %h %s (%cr)" 2>/dev/null || true
    printf '\n'
  done < <(work_repo_dirs)
else
  echo "- no global git user.email configured"
fi

printf '\nToday / active worktrees:\n'
"$WORK_SKILL_DIR/scripts/work-list.sh"

printf '\nAssigned open issues:\n'
work_list_assigned_issues | jq -r '.[] | "- [\(.repository.name) #\(.number)] \(.title) \(.url)"'

printf '\nBlockers to check:\n'
echo "- dirty worktrees"
echo "- PRs without recent updates"
echo "- failing checks or merge conflicts"
