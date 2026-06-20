#!/usr/bin/env bash
# Git, workspace, and worktree helpers.

work_remote_slug() {
  # Args: $1 = git remote URL. Prints owner/repo for common GitHub URL forms.
  local remote="$1"
  remote="${remote%.git}"

  case "$remote" in
    git@*:*)
      printf '%s\n' "${remote#*:}"
      ;;
    *://*/*/*)
      printf '%s\n' "$remote" | sed -E 's|^[a-zA-Z][a-zA-Z0-9+.-]*://([^@/]+@)?[^/]+/([^/]+/[^/]+)$|\2|'
      ;;
    */*)
      printf '%s\n' "$remote" | sed -E 's|^.*/([^/]+/[^/]+)$|\1|'
      ;;
    *)
      printf '%s\n' "$remote"
      ;;
  esac
}

work_remote_owner() {
  work_remote_slug "$1" | cut -d/ -f1
}

work_remote_repo() {
  work_remote_slug "$1" | cut -d/ -f2
}

work_detect_workspace() {
  if git rev-parse --show-toplevel >/dev/null 2>&1; then
    REPO_ROOT="$(git rev-parse --show-toplevel)"
    case "$REPO_ROOT" in
      */.worktrees/*/*)
        WORKSPACE_ROOT="${REPO_ROOT%%/.worktrees/*}"
        local worktree_rel
        worktree_rel="${REPO_ROOT#"$WORKSPACE_ROOT/.worktrees/"}"
        SCOPE="${worktree_rel%%/*}"
        ;;
      *)
        WORKSPACE_ROOT="$(dirname "$REPO_ROOT")"
        SCOPE="$(basename "$REPO_ROOT")"
        ;;
    esac
  else
    WORKSPACE_ROOT="$PWD"
    SCOPE="all"
    if [ -z "$(find . -maxdepth 2 -type d -name .git -print -quit 2>/dev/null)" ]; then
      echo "Not in a git repo, and no git repos found at depth <= 2." >&2
      return 1
    fi
  fi
  export WORKSPACE_ROOT SCOPE
}

work_detect_org() {
  # Args: $1 = repo dir (defaults to first repo under WORKSPACE_ROOT)
  local repo="${1:-}"
  if [ -z "$repo" ]; then
    repo="$(find "$WORKSPACE_ROOT" -maxdepth 2 -type d -name .git -exec dirname {} \; -quit 2>/dev/null)"
  fi
  [ -n "$repo" ] || { echo "No git repo found for org detection." >&2; return 1; }
  local remote
  remote="$(git -C "$repo" remote get-url origin 2>/dev/null)"
  [ -n "$remote" ] || { echo "No origin remote found in $repo." >&2; return 1; }
  ORG="$(work_remote_owner "$remote")"
  export ORG
}

work_default_branch() {
  # Args: $1 = repo dir. Prefer origin/HEAD so non-main repos still branch correctly.
  local repo_dir="${1:-${REPO_ROOT:-$PWD}}"
  local remote_head

  if [ -n "${WORK_DEFAULT_BRANCH:-}" ]; then
    printf '%s\n' "$WORK_DEFAULT_BRANCH"
    return
  fi

  remote_head="$(git -C "$repo_dir" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || true)"
  if [ -n "$remote_head" ]; then
    printf '%s\n' "${remote_head#origin/}"
    return
  fi

  printf '%s\n' "main"
}

work_base_ref() {
  local repo_dir="${1:-${REPO_ROOT:-$PWD}}"
  printf 'origin/%s\n' "$(work_default_branch "$repo_dir")"
}

work_fetch_base() {
  # Args: $1 = repo dir. Fetches the remote base before a new worktree branch is cut.
  local repo_dir="$1"
  git -C "$repo_dir" fetch origin "$(work_default_branch "$repo_dir")"
}

work_create_worktree() {
  # Args: $1 = repo dir, $2 = worktree path, $3 = new branch name.
  local repo_dir="$1"
  local worktree_path="$2"
  local branch="$3"

  if [ -d "$worktree_path" ]; then
    git -C "$worktree_path" rev-parse --show-toplevel >/dev/null 2>&1 || return 1
    printf '%s\n' "$worktree_path"
    return 0
  fi

  if git -C "$repo_dir" show-ref --verify --quiet "refs/heads/$branch"; then
    git -C "$repo_dir" worktree add "$worktree_path" "$branch" >&2
  else
    work_fetch_base "$repo_dir" || return 1
    git -C "$repo_dir" worktree add "$worktree_path" -b "$branch" "$(work_base_ref "$repo_dir")" >&2
  fi
  printf '%s\n' "$worktree_path"
}

work_ensure_gitignore() {
  touch "$WORKSPACE_ROOT/.gitignore"
  grep -qxF ".worktrees/" "$WORKSPACE_ROOT/.gitignore" \
    || echo ".worktrees/" >> "$WORKSPACE_ROOT/.gitignore"
}

work_repo_dirs() {
  # Prints direct child git repo dirs under the workspace.
  find "$WORKSPACE_ROOT" -maxdepth 2 -type d -name .git -exec dirname {} \; 2>/dev/null | sort
}

work_worktree_dirs() {
  # Prints active worktree dirs managed by this skill.
  [ -d "$WORKSPACE_ROOT/.worktrees" ] || return 0
  find "$WORKSPACE_ROOT/.worktrees" -mindepth 2 -maxdepth 2 -type d 2>/dev/null | sort
}

work_repo_for_worktree() {
  # Args: $1 = worktree dir. Prints the repo name from .worktrees/<repo>/<slug>.
  local worktree_path="$1"
  local rel
  case "$worktree_path" in
    "$WORKSPACE_ROOT/.worktrees/"*) ;;
    *) basename "$worktree_path"; return ;;
  esac
  rel="${worktree_path#"$WORKSPACE_ROOT/.worktrees/"}"
  printf '%s\n' "${rel%%/*}"
}

work_primary_repo_dir() {
  # Args: $1 = repo name, $2 = fallback git dir.
  local repo="$1"
  local fallback="${2:-$PWD}"
  if [ -d "$WORKSPACE_ROOT/$repo/.git" ]; then
    printf '%s\n' "$WORKSPACE_ROOT/$repo"
  else
    printf '%s\n' "$fallback"
  fi
}

work_find_worktree() {
  # Args: $1 = optional issue id, branch substring, or path. Prints matching worktree dirs.
  local query="${1:-}"
  local worktree_path
  local branch
  local issue

  if [ -n "$query" ] && [ -d "$query/.git" ]; then
    printf '%s\n' "$(cd "$query" && pwd -P)"
    return
  fi

  while IFS= read -r worktree_path; do
    git -C "$worktree_path" rev-parse --show-toplevel >/dev/null 2>&1 || continue
    branch="$(git -C "$worktree_path" branch --show-current 2>/dev/null || true)"
    issue="$(work_issue_from_branch "$branch" 2>/dev/null || true)"

    if [ -z "$query" ] \
      || [ "$query" = "$issue" ] \
      || [ "$query" = "$branch" ] \
      || [[ "$branch" == *"$query"* ]] \
      || [[ "$worktree_path" == *"$query"* ]]; then
      printf '%s\n' "$worktree_path"
    fi
  done < <(work_worktree_dirs)
}
