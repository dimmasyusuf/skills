#!/usr/bin/env bash
set -euo pipefail

WORK_SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$WORK_SKILL_DIR/scripts/lib.sh"

tmp="$(mktemp -d)"
tmp="$(cd "$tmp" && pwd -P)"
trap 'rm -rf "$tmp"' EXIT

env_file="$tmp/.env.local"

work_env_setup__example_app() {
  local target="${1:-.env.local}"
  cat > "$target" <<'ENV'
APP_URL=https://example.invalid
API_URL=https://api.example.invalid
SECRET_TOKEN=do-not-print
ENV
  work_set_env_value "$target" "APP_URL" "http://localhost:3000"
  work_set_env_value "$target" "API_URL" "http://localhost:8080/api"
  echo "Prepared $target without printing secret values."
}

output="$(work_env_setup__example_app "$env_file")"

assert_contains() {
  local needle="$1"
  local haystack="$2"
  local message="$3"

  if ! grep -qF "$needle" <<<"$haystack"; then
    printf '%s\nmissing: %s\n' "$message" "$needle" >&2
    exit 1
  fi
}

assert_not_contains() {
  local needle="$1"
  local haystack="$2"
  local message="$3"

  if grep -qF "$needle" <<<"$haystack"; then
    printf '%s\nunexpected: %s\n' "$message" "$needle" >&2
    exit 1
  fi
}

env_contents="$(cat "$env_file")"
assert_contains "APP_URL=http://localhost:3000" "$env_contents" "APP_URL should be patched"
assert_contains "API_URL=http://localhost:8080/api" "$env_contents" "API_URL should be patched"
assert_not_contains "do-not-print" "$output" "hook output should not print secret values"
