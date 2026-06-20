#!/usr/bin/env bash
# GitHub Projects API helpers.

work_graphql_owner_project_expr() {
  # Args: $1 = owner login. Prints the GraphQL owner project expression.
  local owner="$1"

  if [ "${WORK_PROJECT_OWNER_TYPE:-org}" = "viewer" ] || [ "$owner" = "@me" ]; then
    # shellcheck disable=SC2016
    printf 'viewer { projectV2(number: $number) { items(first: $first, after: $cursor) { nodes { id content { ... on Issue { url } ... on PullRequest { url } } } pageInfo { hasNextPage endCursor } } } }'
  elif [ "${WORK_PROJECT_OWNER_TYPE:-org}" = "user" ]; then
    # shellcheck disable=SC2016
    printf 'user(login: $owner) { projectV2(number: $number) { items(first: $first, after: $cursor) { nodes { id content { ... on Issue { url } ... on PullRequest { url } } } pageInfo { hasNextPage endCursor } } } }'
  else
    # shellcheck disable=SC2016
    printf 'organization(login: $owner) { projectV2(number: $number) { items(first: $first, after: $cursor) { nodes { id content { ... on Issue { url } ... on PullRequest { url } } } pageInfo { hasNextPage endCursor } } } }'
  fi
}

work_project_move_in_progress() {
  # Args: $1 = issue URL. Best-effort only; defaults to read-safe skip.
  local issue_url="$1"
  if [ "${WORK_PROJECT_WRITE:-0}" != "1" ] || [ "${WORK_SKIP_PROJECT_BOARD:-0}" = "1" ]; then
    echo "skipped"
    return 0
  fi

  [ -n "${WORK_PROJECT_NUMBER:-}" ] || { echo "skipped"; return 0; }
  [ -n "${WORK_PROJECT_OWNER:-${ORG:-}}" ] || { echo "skipped"; return 0; }
  [ -n "${WORK_PROJECT_ID:-}" ] || { echo "skipped"; return 0; }
  [ -n "${WORK_PROJECT_STATUS_FIELD:-}" ] || { echo "skipped"; return 0; }
  [ -n "${WORK_PROJECT_IN_PROGRESS_OPTION:-}" ] || { echo "skipped"; return 0; }

  local owner="${WORK_PROJECT_OWNER:-$ORG}"
  local requested_limit="${WORK_PROJECT_ITEM_LIMIT:-200}"
  local item_id
  local owner_expr
  local query
  local cursor="null"
  local first
  local page_json
  local has_next
  owner_expr="$(work_graphql_owner_project_expr "$owner")"
  if [ "${WORK_PROJECT_OWNER_TYPE:-org}" = "viewer" ] || [ "$owner" = "@me" ]; then
    query="query(\$number: Int!, \$first: Int!, \$cursor: String) { $owner_expr }"
  else
    query="query(\$owner: String!, \$number: Int!, \$first: Int!, \$cursor: String) { $owner_expr }"
  fi

  case "$requested_limit" in
    ''|*[!0-9]*) requested_limit=200 ;;
  esac
  [ "$requested_limit" -gt 0 ] || requested_limit=200

  while [ "$requested_limit" -gt 0 ]; do
    first="$requested_limit"
    [ "$first" -le 100 ] || first=100

    if [ "${WORK_PROJECT_OWNER_TYPE:-org}" = "viewer" ] || [ "$owner" = "@me" ]; then
      page_json="$(gh api graphql \
        -f query="$query" \
        -F number="$WORK_PROJECT_NUMBER" \
        -F first="$first" \
        -F cursor="$cursor" 2>/dev/null)" || {
        echo "list-error"
        return 0
      }
    elif ! page_json="$(gh api graphql \
      -f query="$query" \
      -F owner="${owner#@}" \
      -F number="$WORK_PROJECT_NUMBER" \
      -F first="$first" \
      -F cursor="$cursor" 2>/dev/null)"; then
      echo "list-error"
      return 0
    fi

    item_id="$(jq -r --arg issue_url "$issue_url" \
      '(.data.organization? // .data.user? // .data.viewer? // {}) | .projectV2.items.nodes[]? | select(.content.url == $issue_url) | .id' \
      <<<"$page_json" | head -1)"
    [ -z "$item_id" ] || break

    has_next="$(jq -r '((.data.organization? // .data.user? // .data.viewer? // {}) | .projectV2.items.pageInfo.hasNextPage) // false' <<<"$page_json")"
    [ "$has_next" = "true" ] || break
    cursor="$(jq -r '((.data.organization? // .data.user? // .data.viewer? // {}) | .projectV2.items.pageInfo.endCursor) // empty' <<<"$page_json")"
    [ -n "$cursor" ] || break
    requested_limit=$((requested_limit - first))
  done

  [ -n "$item_id" ] || { echo "not-found"; return 0; }

  # shellcheck disable=SC2016
  if ! gh api graphql -f query='
    mutation($project: ID!, $item: ID!, $field: ID!, $option: String!) {
      updateProjectV2ItemFieldValue(input: {
        projectId: $project
        itemId: $item
        fieldId: $field
        value: { singleSelectOptionId: $option }
      }) {
        projectV2Item { id }
      }
    }' \
    -f project="$WORK_PROJECT_ID" \
    -f item="$item_id" \
    -f field="$WORK_PROJECT_STATUS_FIELD" \
    -f option="$WORK_PROJECT_IN_PROGRESS_OPTION" >/dev/null 2>&1; then
    echo "edit-error"
    return 0
  fi
  echo "updated"
}
