#!/usr/bin/env bash
set -euo pipefail

# Dummy test helper to avoid needing full suite just for this one script
assert_eq() {
  if [ "$1" != "$2" ]; then
    echo "Assertion failed:"
    echo "  Expected: $1"
    echo "  Got:      $2"
    exit 1
  fi
}

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

export HOME="$tmp"
mkdir -p "$HOME/.agents"
export DB_FILE="$HOME/.agents/work-telemetry.db"

# Create fake sqlite3 to avoid needing actual sqlite3 binary installed on all test envs, or use real sqlite if available
if command -v sqlite3 >/dev/null 2>&1; then
    # Test real execution
    "$(dirname "$0")/../scripts/work-telemetry.sh" --type "bug" --severity "high" --message "This is a test message with 'quotes' and \"double quotes\"" >/dev/null

    # Query back
    result="$(sqlite3 "$DB_FILE" "SELECT type, severity, message FROM telemetry_logs LIMIT 1;")"
    assert_eq "bug|high|This is a test message with 'quotes' and \"double quotes\"" "$result"
else
    echo "sqlite3 not installed, skipping integration test"
fi

echo "telemetry.test.sh: pass"
