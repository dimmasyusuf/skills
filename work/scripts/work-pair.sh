#!/usr/bin/env bash
set -euo pipefail

WORK_SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$WORK_SKILL_DIR/scripts/lib.sh"

usage() {
  cat <<'EOF'
Usage: work-pair.sh <issue-ref-a> <issue-ref-b>

Creates or reuses two related issue worktrees using the same start-work path.
EOF
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  usage
  exit 0
fi

if [ "$#" -ne 2 ]; then
  usage >&2
  exit 2
fi

first_ref="$1"
second_ref="$2"

work_init

first_json="$(work_resolve_issue "$first_ref")"
second_json="$(work_resolve_issue "$second_ref")"

first_title="$(jq -r '.repository.name + "#" + (.number | tostring) + ": " + .title' <<<"$first_json")"
second_title="$(jq -r '.repository.name + "#" + (.number | tostring) + ": " + .title' <<<"$second_json")"

printf 'Pair A: %s\n' "$first_title"
printf 'Pair B: %s\n' "$second_title"

"$WORK_SKILL_DIR/scripts/work-start.sh" "$first_ref"
"$WORK_SKILL_DIR/scripts/work-start.sh" "$second_ref"

cat <<'EOF'

Pair checklist:
1. Read AGENTS.md in both worktrees.
2. Confirm env wiring and service ports before implementation.
3. Keep commits and verification separate per issue unless the user asks otherwise.
EOF
