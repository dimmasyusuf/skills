#!/usr/bin/env bash
set -euo pipefail

WORK_SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

tmp="$(mktemp -d)"
tmp="$(cd "$tmp" && pwd -P)"
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/workspace/example-api" "$tmp/workspace/.worktrees/example-api/123-test" "$tmp/bin"
git -C "$tmp/workspace/example-api" init -q
git -C "$tmp/workspace/example-api" remote add origin "https://github.com/example-org/example-api.git"
git -C "$tmp/workspace/.worktrees/example-api/123-test" init -q
git -C "$tmp/workspace/.worktrees/example-api/123-test" checkout -q -b fix/123-test

cat > "$tmp/bin/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

case "$1 $2" in
  "auth status")
    ;;
  "api repos/example-org/example-api/issues/123")
    printf '{"number":123,"state":"open","html_url":"https://github.com/example-org/example-api/issues/123"}\n'
    ;;
  *)
    echo "unexpected gh command during cleanup safety test: $*" >&2
    exit 1
    ;;
esac
EOF
chmod +x "$tmp/bin/gh"

PATH="$tmp/bin:$PATH"
export PATH
hash -r

(
  cd "$tmp/workspace"
  output="$("$WORK_SKILL_DIR/scripts/work-cleanup.sh" 123)"
  case "$output" in
    *"KEEP "*"issue #123 is open"*) ;;
    *) echo "cleanup should keep open issue worktrees" >&2; exit 1 ;;
  esac
)

[ -d "$tmp/workspace/.worktrees/example-api/123-test" ] || {
  echo "cleanup removed an open issue worktree" >&2
  exit 1
}
