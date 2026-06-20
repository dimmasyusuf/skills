#!/usr/bin/env bash
# Text normalization helpers for issue-driven work.

work_label_to_type() {
  # Args: $1 = newline-separated labels. Single labels also work.
  local labels="$1"
  local normalized_labels
  normalized_labels="$(printf '%s\n' "$labels" | sed '/^$/d' | tr '[:upper:]' '[:lower:]')"

  if [ -n "${WORK_LABEL_TO_TYPE:-}" ] && command -v jq >/dev/null 2>&1; then
    local override
    local labels_json
    labels_json="$(printf '%s\n' "$normalized_labels" | jq -R -s 'split("\n") | map(select(length > 0))')"
    override="$(jq -r --argjson labels "$labels_json" '
      to_entries[] as $entry
      | select($labels | index($entry.key | ascii_downcase))
      | $entry.value
    ' <<<"$WORK_LABEL_TO_TYPE" 2>/dev/null | head -1)"
    [ -n "$override" ] && [ "$override" != "null" ] && { echo "$override"; return; }
  fi

  if grep -Eqx 'bug|fix|bugfix' <<<"$normalized_labels"; then
    echo "fix"
  elif grep -Eqx 'feature|enhancement' <<<"$normalized_labels"; then
    echo "feat"
  elif grep -Eqx 'chore|maintenance' <<<"$normalized_labels"; then
    echo "chore"
  elif grep -Eqx 'refactor' <<<"$normalized_labels"; then
    echo "refactor"
  elif grep -Eqx 'docs|documentation' <<<"$normalized_labels"; then
    echo "docs"
  elif grep -Eqx 'test|testing' <<<"$normalized_labels"; then
    echo "test"
  elif grep -Eqx 'perf|performance' <<<"$normalized_labels"; then
    echo "perf"
  else
    echo "feat"
  fi
}

work_slug() {
  # Args: $1 = raw title to kebab slug, max 50 chars
  echo "$1" | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9]/-/g; s/--*/-/g; s/^-//; s/-$//' \
    | cut -c1-50 | sed 's/-$//'
}

work_session_title() {
  # Args: $1 = repo, $2 = issue number, $3 = issue title.
  # Format must stay parseable by session-history and EOD workflows.
  local repo="$1"
  local issue="$2"
  local title="$3"
  local normalized_title

  issue="${issue#\#}"
  normalized_title="$(echo "$title" | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//')"

  printf '%s#%s: %s\n' "$repo" "$issue" "$normalized_title"
}

work_normalize_issue_ref() {
  # Args: $1 = 123, #123, GH-123, or GitHub issue URL. Prints the numeric id.
  local ref="$1"
  ref="${ref##*/issues/}"
  ref="${ref#GH-}"
  ref="${ref#gh-}"
  ref="${ref#\#}"
  ref="$(printf '%s\n' "$ref" | sed -E 's/[^0-9].*$//')"

  case "$ref" in
    ''|*[!0-9]*)
      echo "Invalid issue reference: $1" >&2
      return 1
      ;;
    *)
      printf '%s\n' "$ref"
      ;;
  esac
}

work_issue_from_branch() {
  # Args: $1 = branch name like fix/123-title. Prints the issue id when present.
  local branch="$1"
  branch="${branch#*/}"
  branch="${branch%%-*}"

  case "$branch" in
    ''|*[!0-9]*) return 1 ;;
    *) printf '%s\n' "$branch" ;;
  esac
}
