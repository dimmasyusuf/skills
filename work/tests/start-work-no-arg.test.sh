#!/usr/bin/env bash
set -euo pipefail

WORK_SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

assert_contains() {
  local needle="$1"
  local haystack="$2"
  local message="$3"

  if ! grep -qF "$needle" <<<"$haystack"; then
    printf '%s\nmissing: %s\n' "$message" "$needle" >&2
    exit 1
  fi
}

tmp="$(mktemp -d)"
tmp="$(cd "$tmp" && pwd -P)"
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/workspace/example-api" "$tmp/workspace/example-app"
git -C "$tmp/workspace/example-api" init -q
git -C "$tmp/workspace/example-api" remote add origin "https://github.com/example-org/example-api.git"
git -C "$tmp/workspace/example-app" init -q
git -C "$tmp/workspace/example-app" remote add origin "https://github.com/example-org/example-app.git"

bin="$tmp/bin"
mkdir -p "$bin"
cat > "$bin/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

case "$1 $2" in
  "auth status")
    ;;
  "api -X")
    case "${GH_SEARCH_MODE:-one}" in
      none)
        printf '[]\n'
        ;;
      multiple)
        cat <<'JSON'
[
  {"repository":{"name":"example-api","nameWithOwner":"example-org/example-api"},"number":1679,"title":"Backend issue","labels":[{"name":"bug"}],"url":"https://github.com/example-org/example-api/issues/1679"},
  {"repository":{"name":"example-app","nameWithOwner":"example-org/example-app"},"number":2535,"title":"Frontend issue","labels":[{"name":"bug"}],"url":"https://github.com/example-org/example-app/issues/2535"}
]
JSON
        ;;
      *)
        cat <<'JSON'
[
  {"repository":{"name":"example-api","nameWithOwner":"example-org/example-api"},"number":1679,"title":"Webhook sync does not mirror status until manual refresh","labels":[{"name":"bug"}],"url":"https://github.com/example-org/example-api/issues/1679"}
]
JSON
        ;;
    esac
    ;;
  "api repos/example-org/example-api/issues/1679")
    cat <<'JSON'
{"number":1679,"title":"Webhook sync does not mirror status until manual refresh","body":"body","labels":[{"name":"bug"}],"state":"open","html_url":"https://github.com/example-org/example-api/issues/1679"}
JSON
    ;;
  *)
    echo "unexpected gh command during no-arg start: $*" >&2
    exit 1
    ;;
esac
EOF
chmod +x "$bin/gh"

PATH="$bin:$PATH"
export PATH
hash -r

(
  cd "$tmp/workspace"
  output="$("$WORK_SKILL_DIR/scripts/work-start.sh" --resolve-only)"
  assert_contains "Session title: example-api#1679: webhook sync does not mirror status until manual refresh" "$output" "no-arg start should auto-pick one assigned issue"
)

(
  cd "$tmp/workspace"
  GH_SEARCH_MODE="multiple"
  export GH_SEARCH_MODE
  set +e
  output="$("$WORK_SKILL_DIR/scripts/work-start.sh" --resolve-only 2>&1)"
  status=$?
  set -e
  [ "$status" -eq 2 ] || { echo "multiple assigned issues should require a choice" >&2; exit 1; }
  assert_contains "Multiple assigned open issues found" "$output" "multiple assigned issues should be reported"
)

(
  cd "$tmp/workspace"
  GH_SEARCH_MODE="none"
  export GH_SEARCH_MODE
  set +e
  output="$("$WORK_SKILL_DIR/scripts/work-start.sh" --resolve-only 2>&1)"
  status=$?
  set -e
  [ "$status" -eq 1 ] || { echo "no assigned issues should stop cleanly" >&2; exit 1; }
  assert_contains "No assigned open issues found" "$output" "empty assigned issue list should be reported"
)
