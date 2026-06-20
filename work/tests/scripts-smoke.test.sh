#!/usr/bin/env bash
set -euo pipefail

WORK_SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$WORK_SKILL_DIR/scripts/lib.sh"

tmp="$(mktemp -d)"
tmp="$(cd "$tmp" && pwd -P)"
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/skills/example/agents"
cat > "$tmp/skills/example/SKILL.md" <<'EOF'
---
name: "example"
description: "Use when testing skill list output."
---

# Example
EOF
cat > "$tmp/skills/example/agents/openai.yaml" <<'EOF'
interface:
  display_name: "Example"
EOF

"$WORK_SKILL_DIR/scripts/work-start.sh" --help >/dev/null
"$WORK_SKILL_DIR/scripts/work-list.sh" --help >/dev/null
"$WORK_SKILL_DIR/scripts/work-resume.sh" --help >/dev/null
"$WORK_SKILL_DIR/scripts/work-sync.sh" --help >/dev/null
"$WORK_SKILL_DIR/scripts/work-cleanup.sh" --help >/dev/null
"$WORK_SKILL_DIR/scripts/work-verify.sh" --help >/dev/null
"$WORK_SKILL_DIR/scripts/work-standup.sh" --help >/dev/null
"$WORK_SKILL_DIR/scripts/work-pair.sh" --help >/dev/null
"$WORK_SKILL_DIR/scripts/util-list-skills.sh" "$tmp/skills" | grep -q $'example\texample\tUse when testing skill list output.\topenai.yaml'
work_superpower_required_skills | grep -q 'superpowers:test-driven-development'
work_superpower_preflight_message | grep -q 'tool_search'
