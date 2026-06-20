#!/usr/bin/env bash
# GitHub API helpers.

work_issue_json_for_repo() {
  # Args: $1 = repo name, $2 = issue number.
  local repo="$1"
  local issue="$2"
  local issue_json

  issue_json="$(gh api "repos/$ORG/$repo/issues/$issue")" || return 1
  if jq -e 'has("pull_request")' >/dev/null <<<"$issue_json"; then
    echo "GitHub ref $ORG/$repo#$issue is a pull request, not an issue." >&2
    return 3
  fi

  jq --arg org "$ORG" --arg repo "$repo" \
      '{
        number,
        title,
        body,
        labels,
        state,
        url: .html_url,
        repository: {name: $repo, nameWithOwner: ($org + "/" + $repo)}
      }' <<<"$issue_json"
}

work_resolve_issue() {
  # Args: $1 = issue ref. Prints gh issue JSON with repository, number, title, labels, state, url.
  local raw_ref="$1"
  local issue
  local repo=""

  issue="$(work_normalize_issue_ref "$raw_ref")" || return 1

  case "$raw_ref" in
    https://github.com/*/*/issues/*)
      repo="$(printf '%s\n' "$raw_ref" | sed -E 's|https://github.com/[^/]+/([^/]+)/issues/[0-9]+.*|\1|')"
      ;;
  esac

  if [ -n "$repo" ]; then
    work_issue_json_for_repo "$repo" "$issue"
    return
  fi

  if [ "${SCOPE:-all}" != "all" ]; then
    work_issue_json_for_repo "$SCOPE" "$issue"
    return
  fi

  local repo_dir
  local issue_tmp
  local issue_err
  local issue_status
  issue_tmp="$(mktemp)"
  issue_err="$(mktemp)"
  while IFS= read -r repo_dir; do
    repo="$(basename "$repo_dir")"
    if work_issue_json_for_repo "$repo" "$issue" >"$issue_tmp" 2>"$issue_err"; then
      cat "$issue_tmp"
      rm -f "$issue_tmp" "$issue_err"
      return
    else
      issue_status=$?
      if [ "$issue_status" -eq 3 ]; then
        cat "$issue_err" >&2
        rm -f "$issue_tmp" "$issue_err"
        return 1
      fi
    fi
  done < <(work_repo_dirs)
  rm -f "$issue_tmp" "$issue_err"

  echo "Issue #$issue was not found in local workspace repos under $ORG." >&2
  return 1
}

work_list_assigned_issues() {
  local limit="${WORK_ISSUE_SEARCH_LIMIT:-50}"
  gh api -X GET search/issues \
    -f q="org:$ORG assignee:@me state:open type:issue" \
    -F per_page="$limit" \
    --jq '.items | map(select(has("pull_request") | not) | {
      repository: {
        name: (.repository_url | split("/")[-1]),
        nameWithOwner: (.repository_url | split("/")[-2:] | join("/"))
      },
      number,
      title,
      labels,
      url: .html_url
	    })'
}

work_branch_pull_json() {
  # Args: $1 = repo, $2 = branch. Prints the first PR JSON for the branch.
  local repo="$1"
  local branch="$2"

  gh api -X GET "repos/$ORG/$repo/pulls" \
    -f head="$ORG:$branch" \
    -f state=all \
    --jq '.[0] // empty'
}

work_branch_pr_summary() {
  # Args: $1 = repo, $2 = branch. Prints a compact PR state.
  local repo="$1"
  local branch="$2"
  local pr_json

  pr_json="$(work_branch_pull_json "$repo" "$branch" 2>/dev/null || true)"
  if [ -z "$pr_json" ]; then
    echo "no-pr"
    return
  fi

  jq -r '
    "#" + (.number | tostring) + " " + .state
    + (if .merged_at then " merged" else "" end)
  ' <<<"$pr_json"
}

work_branch_has_open_pr() {
  # Args: $1 = repo, $2 = branch.
  local repo="$1"
  local branch="$2"
  local pr_json

  pr_json="$(work_branch_pull_json "$repo" "$branch" 2>/dev/null || true)"
  [ -n "$pr_json" ] && [ "$(jq -r '.state // empty' <<<"$pr_json")" = "open" ]
}

work_branch_pr_merged() {
  # Args: $1 = repo, $2 = branch.
  local repo="$1"
  local branch="$2"
  local pr_json

  pr_json="$(work_branch_pull_json "$repo" "$branch" 2>/dev/null || true)"
  [ -n "$pr_json" ] && [ "$(jq -r '.merged_at // empty' <<<"$pr_json")" != "" ]
}
