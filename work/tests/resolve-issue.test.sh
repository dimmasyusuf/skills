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

mkdir -p "$tmp/workspace/example-api"
git -C "$tmp/workspace/example-api" init -q
git -C "$tmp/workspace/example-api" remote add origin "https://github.com/example-org/example-api.git"

bin="$tmp/bin"
mkdir -p "$bin"
cat > "$bin/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

case "$1 $2" in
  "api repos/example-org/example-api/issues/1679")
    cat <<'JSON'
{"number":1679,"title":"Webhook sync does not mirror status until manual refresh","body":"body","labels":[{"name":"bug"}],"state":"open","html_url":"https://github.com/example-org/example-api/issues/1679"}
JSON
    ;;
  "api repos/example-org/example-api/issues/1680")
    cat <<'JSON'
{"number":1680,"title":"Do not resolve pull requests as issues","body":"body","labels":[{"name":"bug"}],"state":"open","html_url":"https://github.com/example-org/example-api/pull/1680","pull_request":{"url":"https://api.github.com/repos/example-org/example-api/pulls/1680","html_url":"https://github.com/example-org/example-api/pull/1680"}}
JSON
    ;;
  "api -X")
    if [ "$3" != "GET" ] || [ "$4" != "search/issues" ]; then
      echo "unexpected search args: $*" >&2
      exit 1
    fi
    cat <<'JSON'
[{"repository":{"name":"example-api","nameWithOwner":"example-org/example-api"},"number":1679,"title":"Webhook sync does not mirror status until manual refresh","labels":[{"name":"bug"}],"url":"https://github.com/example-org/example-api/issues/1679"}]
JSON
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

WORKSPACE_ROOT="$tmp/workspace"
ORG="example-org"
SCOPE="all"
export WORKSPACE_ROOT ORG SCOPE

json="$(work_resolve_issue "1679")"
assert_eq "$(jq -r '.repository.name' <<<"$json")" "example-api" "bare issue resolves repo from workspace"
assert_eq "$(jq -r '.number' <<<"$json")" "1679" "bare issue resolves number"

json="$(work_resolve_issue "https://github.com/example-org/example-api/issues/1679")"
assert_eq "$(jq -r '.repository.name' <<<"$json")" "example-api" "url issue resolves repo directly"

if work_resolve_issue "1680" >"$tmp/pr.json" 2>"$tmp/pr.err"; then
  echo "pull request refs should not resolve as work issues" >&2
  exit 1
fi
case "$(cat "$tmp/pr.err")" in
  *"pull request"*) ;;
  *) echo "pull request rejection should explain the problem" >&2; exit 1 ;;
esac

json="$(work_list_assigned_issues)"
assert_eq "$(jq -r '.[0].repository.name' <<<"$json")" "example-api" "assigned issues are listed through gh api"
