#!/usr/bin/env bash
set -euo pipefail

WORK_SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$WORK_SKILL_DIR/scripts/lib.sh"

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  if [ "$actual" != "$expected" ]; then
    printf '%s\nexpected: %s\nactual:   %s\n' "$message" "$expected" "$actual" >&2
    exit 1
  fi
}

tmp="$(mktemp -d)"
tmp="$(cd "$tmp" && pwd -P)"
trap 'rm -rf "$tmp"' EXIT

bin="$tmp/bin"
mkdir -p "$bin"

cat > "$bin/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "$*" | tr '\n' ' ' >> "$GH_CALLS"
printf '\n' >> "$GH_CALLS"

cmd="$1 $2"
all_args="$*"
jq_filter=""
cursor=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --jq)
      jq_filter="$2"
      shift 2
      ;;
    -F)
      case "${2:-}" in
        cursor=*) cursor="${2#cursor=}" ;;
      esac
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

emit() {
  local json="$1"
  if [ -n "$jq_filter" ]; then
    jq -r "$jq_filter" <<<"$json"
  else
    printf '%s\n' "$json"
  fi
}

case "$cmd" in
  "api graphql")
    case "$all_args" in
      *"updateProjectV2ItemFieldValue"*)
        [ "${GH_PROJECT_MODE:-success}" != "edit-error" ] || exit 1
        printf '{"data":{"updateProjectV2ItemFieldValue":{"projectV2Item":{"id":"PVTI_item_1"}}}}\n'
        ;;
	      *)
	        [ "${GH_PROJECT_MODE:-success}" != "list-error" ] || exit 1
	        if [ "$cursor" = "cursor1" ]; then
	          case "$all_args" in
	            *"viewer {"*) emit '{"data":{"viewer":{"projectV2":{"items":{"nodes":[{"id":"PVTI_item_1","content":{"url":"https://github.com/example-org/example-app/issues/123"}}],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}' ;;
	            *) emit '{"data":{"organization":{"projectV2":{"items":{"nodes":[{"id":"PVTI_item_1","content":{"url":"https://github.com/example-org/example-app/issues/123"}}],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}' ;;
	          esac
	        else
	          case "$all_args" in
	            *"viewer {"*) emit '{"data":{"viewer":{"projectV2":{"items":{"nodes":[{"id":"PVTI_other","content":{"url":"https://github.com/example-org/example-app/issues/999"}}],"pageInfo":{"hasNextPage":true,"endCursor":"cursor1"}}}}}}' ;;
	            *) emit '{"data":{"organization":{"projectV2":{"items":{"nodes":[{"id":"PVTI_other","content":{"url":"https://github.com/example-org/example-app/issues/999"}}],"pageInfo":{"hasNextPage":true,"endCursor":"cursor1"}}}}}}' ;;
	          esac
	        fi
	        ;;
    esac
    ;;
  *)
    echo "unexpected gh command: $*" >&2
    exit 1
    ;;
esac
EOF
chmod +x "$bin/gh"

PATH="$bin:$PATH"
export PATH
hash -r
GH_CALLS="$tmp/gh-calls.log"
export GH_CALLS

export WORK_PROJECT_WRITE=1
export WORK_PROJECT_OWNER="example-org"
export WORK_PROJECT_NUMBER="3"
export WORK_PROJECT_ID="PVT_project"
export WORK_PROJECT_STATUS_FIELD="PVTSSF_status"
export WORK_PROJECT_IN_PROGRESS_OPTION="option_progress"
export WORK_PROJECT_ITEM_LIMIT=200
export ORG="example-org"

assert_eq "$(work_project_move_in_progress "https://github.com/example-org/example-app/issues/123")" "updated" "project item updates with IDs"
assert_eq "$(sed -n '1p' "$GH_CALLS" | cut -d' ' -f1-2)" "api graphql" "project item list uses gh api graphql"
case "$(sed -n '1p' "$GH_CALLS")" in
  *"organization(login: "*"-F owner=example-org"*"-F number=3"*"-F first=100"*"-F cursor=null"*) ;;
  *) echo "project item list should use GraphQL owner, project number, page size, and null cursor" >&2; exit 1 ;;
esac
case "$(sed -n '2p' "$GH_CALLS")" in
  *"organization(login: "*"-F owner=example-org"*"-F number=3"*"-F first=100"*"-F cursor=cursor1"*) ;;
  *) echo "project item list should paginate with a cursor when needed" >&2; exit 1 ;;
esac
case "$(sed -n '3p' "$GH_CALLS")" in
  *"updateProjectV2ItemFieldValue"*"project=PVT_project"*"item=PVTI_item_1"*"field=PVTSSF_status"*"option=option_progress"*) ;;
  *) echo "project item edit should use GraphQL project, item, field, and option IDs" >&2; exit 1 ;;
esac

: >"$GH_CALLS"
WORK_PROJECT_OWNER="@me"
WORK_PROJECT_OWNER_TYPE="viewer"
export WORK_PROJECT_OWNER WORK_PROJECT_OWNER_TYPE
assert_eq "$(work_project_move_in_progress "https://github.com/example-org/example-app/issues/123")" "updated" "viewer-owned project item updates with IDs"
case "$(sed -n '1p' "$GH_CALLS")" in
  *"viewer {"*"-F number=3"*"-F first=100"*"-F cursor=null"*) ;;
  *) echo "viewer project item list should use viewer GraphQL without owner login" >&2; exit 1 ;;
esac
case "$(sed -n '1p' "$GH_CALLS")" in
  *"-F owner="*) echo "viewer project item list should not pass an owner variable" >&2; exit 1 ;;
esac
WORK_PROJECT_OWNER="example-org"
WORK_PROJECT_OWNER_TYPE="org"
export WORK_PROJECT_OWNER WORK_PROJECT_OWNER_TYPE

: >"$GH_CALLS"
GH_PROJECT_MODE="list-error"
export GH_PROJECT_MODE
assert_eq "$(work_project_move_in_progress "https://github.com/example-org/example-app/issues/123")" "list-error" "project list failures are explicit and non-blocking"

: >"$GH_CALLS"
GH_PROJECT_MODE="edit-error"
export GH_PROJECT_MODE
assert_eq "$(work_project_move_in_progress "https://github.com/example-org/example-app/issues/123")" "edit-error" "project edit failures are explicit and non-blocking"
