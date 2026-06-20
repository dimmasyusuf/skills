#!/usr/bin/env bash
# Repo hook helpers.

work_hook_name() {
  # Args: $1 = prefix, $2 = repo. Converts repo names to valid bash function names.
  local prefix="$1"
  local repo="$2"
  printf '%s__%s\n' "$prefix" "$(printf '%s\n' "$repo" | tr '-' '_')"
}

work_run_repo_hooks() {
  # Args: $1 = repo name. Runs safety before env setup.
  local repo="$1"
  local safety_hook
  local env_hook
  safety_hook="$(work_hook_name work_safety_check "$repo")"
  env_hook="$(work_hook_name work_env_setup "$repo")"

  if declare -F "$safety_hook" >/dev/null; then
    "$safety_hook" || return 1
  fi

  if declare -F "$env_hook" >/dev/null; then
    "$env_hook" || return 1
  else
    echo "no-env-hook"
    return 0
  fi
}
