#!/usr/bin/env bash
set -euo pipefail

# Dummy test helper
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
# shellcheck disable=SC1091
source "$(dirname "$0")/../scripts/lib/project.sh"

FRONTEND_ENV="$tmp/.env.local"
BACKEND_ENV="$tmp/.env"

# Create dummy env files
echo "EXISTING_KEY=123" > "$FRONTEND_ENV"
echo "EXISTING_KEY=456" > "$BACKEND_ENV"

echo "Testing work_env_patch_tunnel with a valid devtunnel URL..."
work_env_patch_tunnel "$FRONTEND_ENV" "$BACKEND_ENV" "https://0qlmfnc2-3000.asse.devtunnels.ms/" >/dev/null

# Verify frontend env
F_NEXTAUTH="$(grep '^NEXTAUTH_URL=' "$FRONTEND_ENV" | cut -d= -f2-)"
assert_eq "https://0qlmfnc2-3000.asse.devtunnels.ms" "$F_NEXTAUTH"

F_API="$(grep '^BACKEND_API_URL=' "$FRONTEND_ENV" | cut -d= -f2-)"
assert_eq "https://0qlmfnc2-8080.asse.devtunnels.ms" "$F_API"

# Verify backend env
B_FRONTEND="$(grep '^FRONTEND_URL=' "$BACKEND_ENV" | cut -d= -f2-)"
assert_eq "https://0qlmfnc2-3000.asse.devtunnels.ms" "$B_FRONTEND"

B_BACKEND="$(grep '^BACKEND_URL=' "$BACKEND_ENV" | cut -d= -f2-)"
assert_eq "https://0qlmfnc2-8080.asse.devtunnels.ms" "$B_BACKEND"

echo "Testing work_env_patch_tunnel with invalid URL format..."
if work_env_patch_tunnel "$FRONTEND_ENV" "$BACKEND_ENV" "http://localhost:3000" >/dev/null 2>&1; then
  echo "Expected work_env_patch_tunnel to fail with invalid URL format"
  exit 1
fi

echo "tunnel.test.sh: pass"
