#!/usr/bin/env bash
# shellcheck disable=SC2030,SC2031
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

assert_eq "$(work_remote_slug "https://github.com/example-org/example-app.git")" "example-org/example-app" "https remote parses"
assert_eq "$(work_remote_slug "git@github.com:example-org/example-app.git")" "example-org/example-app" "ssh shorthand remote parses"
assert_eq "$(work_remote_slug "ssh://git@github.com/example-org/example-app.git")" "example-org/example-app" "ssh url remote parses"
assert_eq "$(work_remote_owner "https://github.com/example-org/example-app.git")" "example-org" "owner parses from https remote"
assert_eq "$(work_remote_repo "https://github.com/example-org/example-app.git")" "example-app" "repo parses from https remote"

tmp="$(mktemp -d)"
tmp="$(cd "$tmp" && pwd -P)"
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/workspace/example-app"
git -C "$tmp/workspace/example-app" init -q
git -C "$tmp/workspace/example-app" remote add origin "https://github.com/example-org/example-app.git"
git -C "$tmp/workspace/example-app" config user.email "test@example.com"
git -C "$tmp/workspace/example-app" config user.name "Test User"
touch "$tmp/workspace/example-app/file.txt"
git -C "$tmp/workspace/example-app" add file.txt
git -C "$tmp/workspace/example-app" commit -m "initial" >/dev/null
git -C "$tmp/workspace/example-app" update-ref refs/remotes/origin/trunk HEAD
git -C "$tmp/workspace/example-app" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/trunk

(
  cd "$tmp/workspace/example-app"
  work_detect_workspace
  work_detect_org "$PWD"
  assert_eq "$WORKSPACE_ROOT" "$tmp/workspace" "regular checkout workspace root"
  assert_eq "$SCOPE" "example-app" "regular checkout scope"
  assert_eq "$ORG" "example-org" "https origin owner detection"
  assert_eq "$(work_default_branch "$PWD")" "trunk" "origin HEAD default branch detection"
)

(
  cd "$tmp/workspace/example-app"
  WORKSPACE_ROOT="$tmp/workspace"
  unset ORG
  work_detect_org
  assert_eq "$ORG" "example-org" "detect org without args is strict-mode safe"
)



(
  bin="$tmp/bin-work-init"
  mkdir -p "$bin"
  cat > "$bin/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[ "$1 $2" = "auth status" ]
EOF
  chmod +x "$bin/gh"
  PATH="$bin:$PATH"
  export PATH
  hash -r

  cd "$tmp/workspace/example-app"
  unset WORK_ORG ORG WORKSPACE_ROOT SCOPE REPO_ROOT
  work_init
  assert_eq "$WORKSPACE_ROOT" "$tmp/workspace" "work_init detects workspace root under strict mode"
  assert_eq "$ORG" "example-org" "work_init detects org under strict mode"
)

mkdir -p "$tmp/workspace/.worktrees/example-app/2535-test"
git -C "$tmp/workspace/.worktrees/example-app/2535-test" init -q
git -C "$tmp/workspace/.worktrees/example-app/2535-test" remote add origin "https://github.com/example-org/example-app.git"

(
  cd "$tmp/workspace/.worktrees/example-app/2535-test"
  work_detect_workspace
  work_detect_org "$PWD"
  assert_eq "$WORKSPACE_ROOT" "$tmp/workspace" "nested worktree workspace root"
  assert_eq "$SCOPE" "example-app" "nested worktree scope"
  assert_eq "$ORG" "example-org" "nested worktree owner detection"
)

export WORK_LABEL_TO_TYPE='{"story":"chore","incident":"fix"}'
assert_eq "$(work_label_to_type "story")" "chore" "custom label mapping wins"
assert_eq "$(work_label_to_type "incident")" "fix" "custom incident mapping wins"
assert_eq "$(work_label_to_type "Story")" "chore" "custom label mapping is case-insensitive"
unset WORK_LABEL_TO_TYPE
assert_eq "$(work_label_to_type "Bug")" "fix" "default bug label mapping is case-insensitive"
assert_eq "$(work_label_to_type "Enhancement")" "feat" "default enhancement label mapping is case-insensitive"
assert_eq "$(work_label_to_type "debug")" "feat" "label mapping does not match substrings"
assert_eq "$(work_label_to_type "not a bug")" "feat" "label mapping treats multi-word labels exactly"
assert_eq "$(work_label_to_type $'debug\nbug')" "fix" "newline-separated labels can match exact bug label"
export WORK_LABEL_TO_TYPE='{"story":"chore","incident":"fix"}'
assert_eq "$(work_label_to_type "enhancement")" "feat" "default mapping still works"
assert_eq "$(work_label_to_type "story time")" "feat" "custom label mapping is exact"

calls="$tmp/calls.log"
work_env_setup__example_app() {
  printf 'env:%s\n' "$PWD" >> "$calls"
}
work_safety_check__example_app() {
  printf 'safety:%s\n' "$PWD" >> "$calls"
}
(
  cd "$tmp/workspace/example-app"
  work_run_repo_hooks "example-app"
)

assert_eq "$(sed -n '1p' "$calls" | cut -d: -f1)" "safety" "safety hook runs first"
assert_eq "$(sed -n '2p' "$calls" | cut -d: -f1)" "env" "env hook runs second"

assert_eq "$(work_run_repo_hooks "unknown-repo")" "no-env-hook" "missing env hook is non-fatal"

assert_eq "$(work_normalize_issue_ref "123")" "123" "plain issue number normalizes"
assert_eq "$(work_normalize_issue_ref "#123")" "123" "hash issue number normalizes"
assert_eq "$(work_normalize_issue_ref "GH-123")" "123" "GH-prefixed issue number normalizes"
assert_eq "$(work_normalize_issue_ref "https://github.com/example-org/example-app/issues/123")" "123" "issue URL normalizes"

export WORK_SKIP_PROJECT_BOARD=1
assert_eq "$(work_project_move_in_progress "https://github.com/example-org/example-app/issues/1")" "skipped" "project move is skip-safe"
