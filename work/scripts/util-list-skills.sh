#!/usr/bin/env bash
set -euo pipefail

SKILL_HOME="${1:-${AGENT_SKILLS_HOME:-$HOME/.agents/skills}}"

[ -d "$SKILL_HOME" ] || { echo "Skill home not found: $SKILL_HOME" >&2; exit 1; }

if command -v ruby >/dev/null 2>&1; then
  ruby -ryaml -rdate -e '
    Dir[File.join(ARGV[0], "*", "SKILL.md")].sort.each do |f|
      y = YAML.safe_load(File.read(f), permitted_classes: [Date, Time])
      dir = File.basename(File.dirname(f))
      meta = File.join(File.dirname(f), "agents", "openai.yaml")
      puts [dir, y["name"], y["description"], File.exist?(meta) ? "openai.yaml" : "no-openai.yaml"].join("\t")
    end
  ' "$SKILL_HOME"
else
  find "$SKILL_HOME" -mindepth 2 -maxdepth 2 -name SKILL.md -print | sort
fi
