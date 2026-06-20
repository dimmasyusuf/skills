#!/usr/bin/env bash
# Core setup and dependency helpers.

work_source_config() {
  # shellcheck disable=SC1091
  [ -f "$HOME/.config/work/config" ] && source "$HOME/.config/work/config"
  # shellcheck disable=SC1091
    [ -n "${WORK_ORG:-}" ] && ORG="$WORK_ORG"
  export ORG
}

work_verify_deps() {
  gh auth status >/dev/null 2>&1 || { echo "gh not authenticated. Run: gh auth login" >&2; return 1; }
  command -v jq >/dev/null || { echo "jq required. brew install jq" >&2; return 1; }
}

work_detect_pm() {
  # Sets PM and INSTALL globals
  if   [ -f bun.lock ] || [ -f bun.lockb ]; then PM="bun";  INSTALL="bun install"
  elif [ -f pnpm-lock.yaml ];                   then PM="pnpm"; INSTALL="pnpm install"
  elif [ -f yarn.lock ];                        then PM="yarn"; INSTALL="yarn install"
  elif [ -f package-lock.json ];                then PM="npm";  INSTALL="npm install"
  else                                               PM=""; INSTALL=""
  fi
  export PM INSTALL
}

work_init() {
  work_detect_workspace || return 1
  work_detect_org
  work_source_config
  work_verify_deps || return 1
}
