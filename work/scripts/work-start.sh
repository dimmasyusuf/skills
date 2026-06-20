#!/usr/bin/env bash
set -euo pipefail

WORK_SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$WORK_SKILL_DIR/scripts/lib.sh"

usage() {
  cat <<'EOF'
Usage: work-start.sh [--resolve-only] [issue-ref]

Starts issue work from a GitHub issue reference.
Accepted refs: 123, #123, GH-123, or https://github.com/<org>/<repo>/issues/123
With no issue ref, lists assigned open issues and auto-picks only when exactly
one issue is valid in the current workspace scope.

Use --resolve-only first when the AI needs to rename the current thread before
creating or reusing a worktree.

Set WORK_SKIP_INSTALL=1 to skip dependency installation.
EOF
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  usage
  exit 0
fi

resolve_only=0
if [ "${1:-}" = "--resolve-only" ]; then
  resolve_only=1
  shift
fi

work_init
issue_ref="${1:-}"

if [ -z "$issue_ref" ]; then
  assigned_json="$(work_list_assigned_issues)"
  if [ "${SCOPE:-all}" != "all" ]; then
    assigned_json="$(jq --arg scope "$SCOPE" 'map(select(.repository.name == $scope))' <<<"$assigned_json")"
  fi

  issue_count="$(jq 'length' <<<"$assigned_json")"
  case "$issue_count" in
    0)
      echo "No assigned open issues found in scope: ${SCOPE:-all}" >&2
      exit 1
      ;;
    1)
      issue_ref="$(jq -r '.[0].url' <<<"$assigned_json")"
      ;;
    *)
      echo "Multiple assigned open issues found. Choose one and rerun with its issue ref:" >&2
      jq -r '.[] | "- [\(.repository.name) #\(.number)] \(.title) \(.url)"' <<<"$assigned_json" >&2
      exit 2
      ;;
  esac
fi

issue_json="$(work_resolve_issue "$issue_ref")"

repo="$(jq -r '.repository.name // ((.repository.nameWithOwner // "") | split("/")[-1]) // empty' <<<"$issue_json")"
issue="$(jq -r '.number' <<<"$issue_json")"
title="$(jq -r '.title' <<<"$issue_json")"
issue_url="$(jq -r '.url' <<<"$issue_json")"
labels="$(jq -r '.labels[]?.name' <<<"$issue_json")"

[ -n "$repo" ] || { echo "Could not resolve issue repository." >&2; exit 1; }
[ -n "$issue" ] || { echo "Could not resolve issue number." >&2; exit 1; }
[ -n "$title" ] || { echo "Could not resolve issue title." >&2; exit 1; }

type="$(work_label_to_type "$labels")"
slug="$(work_slug "$title")"
branch="${type}/${issue}-${slug}"
repo_dir="$WORKSPACE_ROOT/$repo"
worktree="$WORKSPACE_ROOT/.worktrees/$repo/${issue}-${slug}"
session_title="$(work_session_title "$repo" "$issue" "$title")"

[ -d "$repo_dir/.git" ] || { echo "Repo directory not found: $repo_dir" >&2; exit 1; }

echo "Session title: $session_title"
echo "Issue: $issue_url"
echo "Branch: $branch"
echo "Worktree: $worktree"

if [ "$resolve_only" = "1" ]; then
  cat <<EOF
Repo: $repo
Issue number: $issue

Next AI action:
Rename this thread to: $session_title
Then rerun: $WORK_SKILL_DIR/scripts/work-start.sh "$issue_ref"
EOF
  exit 0
fi

project_status="$(work_project_move_in_progress "$issue_url")"
echo "Project status: $project_status"

work_ensure_gitignore
mkdir -p "$(dirname "$worktree")"
created_path="$(work_create_worktree "$repo_dir" "$worktree" "$branch")"
echo "Worktree ready: $created_path"

(
  cd "$created_path"
  work_detect_pm
  if [ -n "$INSTALL" ] && [ "${WORK_SKIP_INSTALL:-0}" != "1" ]; then
    echo "Installing dependencies with: $INSTALL"
    # shellcheck disable=SC2086
    $INSTALL
  elif [ -n "$INSTALL" ]; then
    echo "Install skipped: $INSTALL"
  else
    echo "No package manager install command detected."
  fi

  hook_result="$(work_run_repo_hooks "$repo")" || exit 1
  [ -n "$hook_result" ] && echo "$hook_result"
  [ "$hook_result" = "no-env-hook" ] && {
    [ -f package.json ] && jq -r '.scripts | to_entries[]? | "script: \(.key) = \(.value)"' package.json
    [ -f .env.example ] && grep -E '^[A-Z_]+=' .env.example | cut -d= -f1
  }
)

if [ -n "$issue" ]; then
  echo "Fetching full issue context to .work_context.md..."
  gh issue view "$issue" --repo "$ORG/$repo" --comments > "$created_path/.work_context.md" 2>/dev/null || echo "Failed to fetch issue context" > "$created_path/.work_context.md"
fi

cat <<EOF

Next AI actions:
1. Confirm this thread is titled: $session_title
2. Read the full issue context in $created_path/.work_context.md.
3. Automatically parse keywords and run context7-mcp or codebase-map skills to pre-fetch context if applicable.
4. If this is a bug, trigger the observability-triage skill to fetch live stack traces or logs.
5. Read $created_path/AGENTS.md if present.
6. Run the pre-work gauntlet from references/gauntlet-00-pre-work.md.
EOF
