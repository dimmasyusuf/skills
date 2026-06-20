#!/usr/bin/env bash
# Generic project local-dev helpers.

work_set_env_value() {
  # Args: $1 = env file, $2 = key, $3 = value. Upserts without printing values.
  local env_file="$1"
  local key="$2"
  local value="$3"

  if [ -f "$env_file" ]; then
    awk -F= -v k="$key" -v v="$value" 'BEGIN {OFS="="; found=0} $1==k {$2=v; print; found=1; next} {print} END {if(!found) print k, v}' "$env_file" > "${env_file}.tmp" && mv "${env_file}.tmp" "$env_file"
  else
    printf '%s=%s\n' "$key" "$value" >> "$env_file"
  fi
}

work_env_patch_tunnel() {
  local frontend_env="${1:-.env.local}"
  local backend_env="${2:-.env}"
  local tunnel_url="$3" # e.g. https://0qlmfnc2-3000.asse.devtunnels.ms/
  local frontend_port="${WORK_TUNNEL_FRONTEND_PORT:-3000}"
  local backend_port="${WORK_TUNNEL_BACKEND_PORT:-8080}"
  local api_path="${WORK_TUNNEL_API_PATH:-}"

  if [ -z "$tunnel_url" ]; then
    echo "Usage: work_env_patch_tunnel <frontend_env> <backend_env> <tunnel_url>" >&2
    return 1
  fi

  # Extract base ID and suffix from url.
  # https://0qlmfnc2-3000.asse.devtunnels.ms/ -> id=0qlmfnc2, suffix=asse.devtunnels.ms
  if [[ "$tunnel_url" =~ ^https?://([a-zA-Z0-9]+)-[0-9]+\.([^/]+) ]]; then
    local tunnel_id="${BASH_REMATCH[1]}"
    local suffix="${BASH_REMATCH[2]}"
    local frontend_url="https://${tunnel_id}-${frontend_port}.${suffix}"
    local backend_url="https://${tunnel_id}-${backend_port}.${suffix}"
    local backend_api_url="${backend_url}${api_path}"

    echo "Patching $frontend_env..."
    work_set_env_value "$frontend_env" "NEXTAUTH_URL" "$frontend_url"
    work_set_env_value "$frontend_env" "NEXT_PUBLIC_BASE_URL" "$frontend_url"
    work_set_env_value "$frontend_env" "BACKEND_API_URL" "$backend_api_url"
    work_set_env_value "$frontend_env" "NEXT_PUBLIC_API_BASE_URL" "$backend_api_url"

    echo "Patching $backend_env..."
    work_set_env_value "$backend_env" "FRONTEND_URL" "$frontend_url"
    work_set_env_value "$backend_env" "BACKEND_URL" "$backend_api_url"

    echo "Tunnel URLs patched successfully!"
  else
    echo "Error: Could not parse dev tunnel URL format from '$tunnel_url'." >&2
    return 1
  fi
}
