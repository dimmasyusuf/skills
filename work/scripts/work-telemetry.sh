#!/usr/bin/env bash
set -euo pipefail

DB_FILE="${HOME}/.agents/work-telemetry.db"

# Initialize DB if it doesn't exist
sqlite3 "$DB_FILE" "CREATE TABLE IF NOT EXISTS telemetry_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    type TEXT,
    severity TEXT,
    message TEXT
);"

TYPE="intercept"
SEVERITY="info"
MESSAGE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --type)
      TYPE="$2"
      shift 2
      ;;
    --severity)
      SEVERITY="$2"
      shift 2
      ;;
    --message)
      MESSAGE="$2"
      shift 2
      ;;
    *)
      echo "Unknown flag $1"
      exit 1
      ;;
  esac
done

if [[ -z "$MESSAGE" ]]; then
    echo "Error: --message is required."
    exit 1
fi

# Sanitize inputs for sqlite3 by replacing single quotes with two single quotes
S_TYPE="$(printf '%s' "$TYPE" | sed "s/'/''/g")"
S_SEVERITY="$(printf '%s' "$SEVERITY" | sed "s/'/''/g")"
S_MESSAGE="$(printf '%s' "$MESSAGE" | sed "s/'/''/g")"

# Insert
sqlite3 "$DB_FILE" <<EOF
INSERT INTO telemetry_logs (type, severity, message) VALUES ('${S_TYPE}', '${S_SEVERITY}', '${S_MESSAGE}');
EOF

echo "Telemetry logged successfully to $DB_FILE"
