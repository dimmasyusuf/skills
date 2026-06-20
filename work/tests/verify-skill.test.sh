#!/usr/bin/env bash
set -euo pipefail

WORK_SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLED_WORK_DIR="${WORK_SKILL_DIR:-${AGENT_SKILLS_HOME:-$HOME/.agents/skills}/work}"

run() {
  printf '\n== %s ==\n' "$*"
  "$@"
}

run bash -n "$WORK_SKILL_DIR/scripts/lib.sh" "$WORK_SKILL_DIR"/scripts/lib/*.sh "$WORK_SKILL_DIR"/tests/*.test.sh "$WORK_SKILL_DIR"/scripts/*.sh

if command -v shellcheck >/dev/null 2>&1; then
  run shellcheck "$WORK_SKILL_DIR/scripts/lib.sh" "$WORK_SKILL_DIR"/scripts/lib/*.sh "$WORK_SKILL_DIR"/scripts/*.sh "$WORK_SKILL_DIR"/tests/*.test.sh
else
  echo "shellcheck not installed"
fi

for test in "$WORK_SKILL_DIR"/tests/*.test.sh; do
  [ "$(basename "$test")" = "verify-skill.test.sh" ] && continue
  run bash "$test"
done

if command -v ruby >/dev/null 2>&1; then
  run ruby -ryaml -e 'ARGV.each { |f| YAML.load_file(f); puts "yaml ok: #{f}" }' \
    "$WORK_SKILL_DIR/SKILL.md" "$WORK_SKILL_DIR/agents/openai.yaml"
fi

if [ -d "$INSTALLED_WORK_DIR" ]; then
  run diff -qr "$WORK_SKILL_DIR" "$INSTALLED_WORK_DIR"
else
  echo "installed work skill not found: $INSTALLED_WORK_DIR"
fi
