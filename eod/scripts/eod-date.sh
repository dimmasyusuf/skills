#!/usr/bin/env bash
set -euo pipefail

json=false
if [ "${1:-}" = "--json" ]; then
  json=true
fi

tz="${EOD_TZ:-${TZ:-UTC}}"
export TZ="$tz"

iso_date="$(date +%Y-%m-%d)"
display_date="$(date "+%A, %d %B" | tr '[:upper:]' '[:lower:]')"
gmail_after="$(date +%Y/%m/%d)"

if [ "$json" = true ]; then
  printf '{"timezone":"%s","iso_date":"%s","display_date":"%s","gmail_after":"%s"}\n' "$tz" "$iso_date" "$display_date" "$gmail_after"
  exit 0
fi

printf 'timezone=%s\n' "$tz"
printf 'iso_date=%s\n' "$iso_date"
printf 'display_date=%s\n' "$display_date"
printf 'gmail_after=%s\n' "$gmail_after"
