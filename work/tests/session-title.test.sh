#!/usr/bin/env bash
set -euo pipefail

WORK_SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$WORK_SKILL_DIR/scripts/lib.sh"

actual="$(work_session_title "example-app" "2535" "Login redirect loop after sign in")"
expected="example-app#2535: login redirect loop after sign in"

if [ "$actual" != "$expected" ]; then
  printf 'expected: %s\nactual:   %s\n' "$expected" "$actual" >&2
  exit 1
fi

actual="$(work_session_title "example-app" "#2535" "Login redirect loop after sign in")"
expected="example-app#2535: login redirect loop after sign in"

if [ "$actual" != "$expected" ]; then
  printf 'expected: %s\nactual:   %s\n' "$expected" "$actual" >&2
  exit 1
fi

actual="$(work_session_title "example-api" "1679" "Webhook sync does not mirror status until manual refresh")"
expected="example-api#1679: webhook sync does not mirror status until manual refresh"

if [ "$actual" != "$expected" ]; then
  printf 'expected: %s\nactual:   %s\n' "$expected" "$actual" >&2
  exit 1
fi
