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

mkdir -p "$tmp/workspace/example-api"
git -C "$tmp/workspace/example-api" init -q
git -C "$tmp/workspace/example-api" remote add origin "https://github.com/example-org/example-api.git"

bin="$tmp/bin"
mkdir -p "$bin"
cat > "$bin/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "$*" >> "$GH_CALLS"

case "$1 $2" in
  "auth status")
    ;;
  "api repos/example-org/example-api/issues/1679")
    cat <<'JSON'
{"number":1679,"title":"Webhook sync does not mirror status until manual refresh","body":"body","labels":[{"name":"Bug"}],"state":"open","html_url":"https://github.com/example-org/example-api/issues/1679"}
JSON
    ;;
  *)
    echo "unexpected gh command during resolve-only: $*" >&2
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

(
  cd "$tmp/workspace/example-api"
  output="$("$WORK_SKILL_DIR/scripts/work-start.sh" --resolve-only 1679)"
  assert_contains "Session title: example-api#1679: webhook sync does not mirror status until manual refresh" "$output" "resolve-only should print deterministic title"
  assert_contains "Branch: fix/1679-webhook-sync-does-not-mirror-status-until" "$output" "resolve-only should infer branch from labels"
  assert_contains "Rename this thread to: example-api#1679: webhook sync does not mirror status until manual refresh" "$output" "resolve-only should stop before worktree creation"
)

if [ -d "$tmp/workspace/.worktrees" ]; then
  echo "resolve-only should not create .worktrees" >&2
  exit 1
fi

if grep -q 'api graphql' "$GH_CALLS"; then
  echo "resolve-only should not touch GitHub Projects" >&2
  exit 1
fi
