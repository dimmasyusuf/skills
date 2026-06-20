#!/usr/bin/env bash
set -euo pipefail

json=false
if [ "${1:-}" = "--json" ]; then
  json=true
fi

tz="${EOD_TZ:-${TZ:-UTC}}"
export TZ="$tz"

today="$(date +%Y-%m-%d)"
index_file="${CODEX_SESSION_INDEX:-$HOME/.codex/session_index.jsonl}"
archive_dir="${CODEX_ARCHIVE_DIR:-$HOME/.codex/archived_sessions}"

if [ "$json" = true ]; then
  if ! command -v jq >/dev/null 2>&1; then
    printf '{"timezone":"%s","date":"%s","session_index":"%s","status":"missing-jq","sessions":[],"recent_archive_candidates":[]}\n' "$tz" "$today" "$index_file"
    exit 0
  fi

  if [ -d "$archive_dir" ]; then
    archives_json="$(find "$archive_dir" -type f -name '*.jsonl' -mtime -2 -print | sort | jq -Rsc 'split("\n") | map(select(length > 0))')"
  else
    archives_json='[]'
  fi

  if [ ! -f "$index_file" ]; then
    sessions_json='[]'
    status='no-session-index'
  else
    sessions_json="$(jq -sc --arg today "$today" '
      def raw_time($x):
        $x.updated_at // $x.updatedAt // $x.updated // $x.lastUpdated //
        $x.last_updated // $x.timestamp // $x.created_at // $x.createdAt // "";
      def local_day($x):
        raw_time($x) as $t |
        if ($t | type) == "number" then
          ($t | strflocaltime("%Y-%m-%d"))
        elif ($t | type) == "string" then
          (try ($t | sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601 | strflocaltime("%Y-%m-%d")) catch ($t[0:10]))
        else
          ""
        end;
      map(
        select(local_day(.) == $today) |
        {
          id: (.id // .session_id // .sessionId // ""),
          updated_at: (raw_time(.) | tostring),
          thread_name: (.thread_name // .threadName // .title // .name // .thread_title // .threadTitle // ""),
          cwd: (.cwd // .workspace // .workspace_dir // .project // ""),
          archive_path: (.path // .archive_path // .archivePath // .file // "")
        }
      )
    ' "$index_file")"
    status='ok'
  fi

  jq -n \
    --arg timezone "$tz" \
    --arg date "$today" \
    --arg session_index "$index_file" \
    --arg status "$status" \
    --argjson sessions "$sessions_json" \
    --argjson recent_archive_candidates "$archives_json" \
    '{timezone:$timezone,date:$date,session_index:$session_index,status:$status,sessions:$sessions,recent_archive_candidates:$recent_archive_candidates}'
  exit 0
fi

printf 'timezone=%s\n' "$tz"
printf 'date=%s\n' "$today"
printf 'session_index=%s\n' "$index_file"

if [ ! -f "$index_file" ]; then
  printf 'status=no-session-index\n'
else
  if ! command -v jq >/dev/null 2>&1; then
    printf 'status=missing-jq\n'
  else
    printf 'sessions_updated_today:\n'
    jq -r --arg today "$today" '
      def raw_time:
        .updated_at // .updatedAt // .updated // .lastUpdated //
        .last_updated // .timestamp // .created_at // .createdAt // "";
      def local_day:
        raw_time as $t |
        if ($t | type) == "number" then
          ($t | strflocaltime("%Y-%m-%d"))
        elif ($t | type) == "string" then
          (try ($t | sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601 | strflocaltime("%Y-%m-%d")) catch ($t[0:10]))
        else
          ""
        end;
      select(local_day == $today) |
      [
        (.id // .session_id // .sessionId // ""),
        (raw_time | tostring),
        (.thread_name // .threadName // .title // .name // .thread_title // .threadTitle // ""),
        (.cwd // .workspace // .workspace_dir // .project // ""),
        (.path // .archive_path // .archivePath // .file // "")
      ] | @tsv
    ' "$index_file"
  fi
fi

if [ -d "$archive_dir" ]; then
  printf 'recent_archive_candidates:\n'
  find "$archive_dir" -type f -name '*.jsonl' -mtime -2 -print | sort
else
  printf 'recent_archive_candidates=none\n'
fi
