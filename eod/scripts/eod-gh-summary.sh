#!/usr/bin/env bash
set -euo pipefail

json=false
if [ "${1:-}" = "--json" ]; then
  json=true
fi

tz="${EOD_TZ:-${TZ:-UTC}}"
export TZ="$tz"

org="${EOD_GH_ORG:-example-org}"
today="$(date +%Y-%m-%d)"
limit="${EOD_GH_LIMIT:-50}"

if [ "$json" = true ]; then
  if ! command -v gh >/dev/null 2>&1; then
    printf '{"timezone":"%s","date":"%s","org":"%s","status":"missing-gh","authored_prs_updated_today":[],"review_requests":[],"assigned_issues":[]}\n' "$tz" "$today" "$org"
    exit 0
  fi

  if ! gh auth status >/dev/null 2>&1; then
    printf '{"timezone":"%s","date":"%s","org":"%s","status":"gh-not-authenticated","authored_prs_updated_today":[],"review_requests":[],"assigned_issues":[]}\n' "$tz" "$today" "$org"
    exit 0
  fi

  if ! command -v jq >/dev/null 2>&1; then
    printf '{"timezone":"%s","date":"%s","org":"%s","status":"missing-jq","authored_prs_updated_today":[],"review_requests":[],"assigned_issues":[]}\n' "$tz" "$today" "$org"
    exit 0
  fi

  login="$(gh api user --jq .login 2>/dev/null || true)"
  authored_json="$(gh search prs --owner "$org" --author "@me" --updated ">=$today" --limit "$limit" --json repository,number,title,state,url,updatedAt 2>/dev/null || printf '[]')"
  reviews_json="$(gh search prs --owner "$org" --review-requested "@me" --state open --limit "$limit" --json repository,number,title,state,url,updatedAt 2>/dev/null || printf '[]')"
  issues_json="$(gh search issues --owner "$org" --assignee "@me" --state open --limit "$limit" --json repository,number,title,state,url,updatedAt 2>/dev/null || printf '[]')"

  jq -n \
    --arg timezone "$tz" \
    --arg date "$today" \
    --arg org "$org" \
    --arg github_user "${login:-unknown}" \
    --arg status "ok" \
    --argjson authored_prs_updated_today "$authored_json" \
    --argjson review_requests "$reviews_json" \
    --argjson assigned_issues "$issues_json" \
    '{timezone:$timezone,date:$date,org:$org,github_user:$github_user,status:$status,authored_prs_updated_today:$authored_prs_updated_today,review_requests:$review_requests,assigned_issues:$assigned_issues}'
  exit 0
fi

printf 'timezone=%s\n' "$tz"
printf 'date=%s\n' "$today"
printf 'org=%s\n' "$org"

if ! command -v gh >/dev/null 2>&1; then
  printf 'status=missing-gh\n'
  exit 0
fi

if ! gh auth status >/dev/null 2>&1; then
  printf 'status=gh-not-authenticated\n'
  exit 0
fi

login="$(gh api user --jq .login 2>/dev/null || true)"
printf 'github_user=%s\n' "${login:-unknown}"

print_search() {
  label="$1"
  shift
  printf '\n%s:\n' "$label"
  if ! "$@" 2>/dev/null; then
    printf 'status=unavailable\n'
  fi
}

jq_pr='.[] | [(.repository.nameWithOwner // .repository.fullName // .repository.name // "unknown"), ("#" + (.number | tostring)), .state, .updatedAt, .title, .url] | @tsv'

print_search "authored_prs_updated_today" \
  gh search prs --owner "$org" --author "@me" --updated ">=$today" --limit "$limit" \
    --json repository,number,title,state,url,updatedAt --jq "$jq_pr"

print_search "review_requests" \
  gh search prs --owner "$org" --review-requested "@me" --state open --limit "$limit" \
    --json repository,number,title,state,url,updatedAt --jq "$jq_pr"

print_search "assigned_issues" \
  gh search issues --owner "$org" --assignee "@me" --state open --limit "$limit" \
    --json repository,number,title,state,url,updatedAt --jq "$jq_pr"
