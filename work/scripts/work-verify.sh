#!/usr/bin/env bash
set -euo pipefail

WORK_SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$WORK_SKILL_DIR/scripts/lib.sh"

usage() {
  cat <<'EOF'
Usage: work-verify.sh

Runs deterministic post-work preflight output from the current worktree. The AI
agent must still follow references/gauntlet-*.md for docs, review, security,
and project-specific test decisions.
EOF
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  usage
  exit 0
fi

work_init

repo_root="$(git rev-parse --show-toplevel)"
repo="$(work_repo_for_worktree "$repo_root")"
branch="$(git -C "$repo_root" branch --show-current)"
issue="$(work_issue_from_branch "$branch" 2>/dev/null || true)"

printf 'Repo: %s\n' "$repo"
printf 'Branch: %s\n' "$branch"
[ -n "$issue" ] && printf 'Issue: %s\n' "$issue"

printf '\nChanged files:\n'
git -C "$repo_root" status --short

printf '\nDiff stat:\n'
git -C "$repo_root" diff --stat

printf '\nDiff names:\n'
git -C "$repo_root" diff --name-only

if [ -n "$issue" ]; then
  printf '\nGitHub issue state:\n'
  gh api "repos/$ORG/$repo/issues/$issue" --jq '{number,title,state,url}'
fi

printf '\nPR state:\n'
work_branch_pr_summary "$repo" "$branch"

printf '\nPackage scripts:\n'
if [ -f "$repo_root/package.json" ]; then
  jq -r '.scripts // {} | to_entries[] | "\(.key): \(.value)"' "$repo_root/package.json"
else
  echo "no package.json"
fi

printf '\nAutomated Test Framework:\n'
if [ -f "$repo_root/package.json" ] && grep -q '"test":' "$repo_root/package.json"; then
  echo "Found NPM test script. (Suggest: npm run test)"
fi
if [ -f "$repo_root/pytest.ini" ] || [ -f "$repo_root/tox.ini" ]; then
  echo "Found Python Pytest. (Suggest: pytest)"
fi
if [ -f "$repo_root/go.mod" ]; then
  echo "Found Go Modules. (Suggest: go test ./...)"
fi

cat <<EOF

Next AI actions:
1. Follow $WORK_SKILL_DIR/references/gauntlet-*.md.
2. Delegate (Dynamic Fleet): Use the invoke_subagent tool to launch as many specialized subagents as necessary based on the file types changed (e.g. "Security Reviewer", "UI/UX Reviewer", "Performance Reviewer", "DB Expert", etc.). Launch them all concurrently to review the diff.
3. Automated Testing: Execute the detected test suites locally for the changed files. Pipe stack traces if they fail.
4. Intelligent Context: Use context7-mcp to fetch API docs for any newly added dependencies in the diff.
5. Run bounded public web research for affected upstream surfaces.
6. Generate a draft PR using the GitHub CLI: gh pr create --title "..." --body "..." --draft
EOF
