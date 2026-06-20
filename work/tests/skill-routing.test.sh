#!/usr/bin/env bash
set -euo pipefail

WORK_SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

required_files=(
  "$WORK_SKILL_DIR/references/guide-trigger-prompts.md"
  "$WORK_SKILL_DIR/references/guide-skills-list.md"
  "$WORK_SKILL_DIR/references/guide-superpowers.md"
  "$WORK_SKILL_DIR/references/guide-project-config.md"
)

for file in "${required_files[@]}"; do
  [ -f "$file" ] || { echo "missing reference: $file" >&2; exit 1; }
done

grep -q 'use the work skill for issue #123' "$WORK_SKILL_DIR/references/guide-trigger-prompts.md"
grep -q 'Do not use work' "$WORK_SKILL_DIR/references/guide-trigger-prompts.md"
grep -q 'superpowers:verification-before-completion' "$WORK_SKILL_DIR/references/guide-superpowers.md"
grep -q 'agent-builder' "$WORK_SKILL_DIR/references/guide-skills-list.md"
grep -q 'work_env_setup__example_app' "$WORK_SKILL_DIR/references/guide-project-config.md"
grep -q 'Senior Engineer Quality Gate' "$WORK_SKILL_DIR"/references/gauntlet-*.md
grep -q 'Uncompromising Utility Reuse' "$WORK_SKILL_DIR"/references/gauntlet-*.md
grep -q 'code-modernization' "$WORK_SKILL_DIR"/references/gauntlet-*.md
grep -q 'code-simplifier' "$WORK_SKILL_DIR"/references/gauntlet-*.md
grep -q 'backend lens' "$WORK_SKILL_DIR"/references/gauntlet-*.md
grep -q 'frontend lens' "$WORK_SKILL_DIR"/references/gauntlet-*.md
grep -q 'Senior engineer quality gate' "$WORK_SKILL_DIR"/SKILL.md
grep -q '## 16. Draft Pull Request Message' "$WORK_SKILL_DIR"/references/gauntlet-*.md
grep -q '## How To Test' "$WORK_SKILL_DIR"/references/gauntlet-*.md
grep -q '## Evidence' "$WORK_SKILL_DIR"/references/gauntlet-*.md
grep -q '## Risk' "$WORK_SKILL_DIR"/references/gauntlet-*.md
grep -q '## Rollback' "$WORK_SKILL_DIR"/references/gauntlet-*.md
grep -q '## Security / Privacy / Data' "$WORK_SKILL_DIR"/references/gauntlet-*.md
grep -q '## Performance / Observability' "$WORK_SKILL_DIR"/references/gauntlet-*.md
grep -q '## Reviewer Checklist' "$WORK_SKILL_DIR"/references/gauntlet-*.md
grep -q '## Screenshots / Recordings' "$WORK_SKILL_DIR"/references/gauntlet-*.md
grep -q '## Breaking Changes / Migration' "$WORK_SKILL_DIR"/references/gauntlet-*.md
grep -q '## Dependencies' "$WORK_SKILL_DIR"/references/gauntlet-*.md
grep -q '## Deployment / Operations' "$WORK_SKILL_DIR"/references/gauntlet-*.md
grep -q '## Compatibility' "$WORK_SKILL_DIR"/references/gauntlet-*.md
grep -q '## Follow-Ups' "$WORK_SKILL_DIR"/references/gauntlet-*.md
grep -q '## PR Type' "$WORK_SKILL_DIR"/references/gauntlet-*.md
grep -q '## Accessibility' "$WORK_SKILL_DIR"/references/gauntlet-*.md
grep -q 'Dynamic section selection' "$WORK_SKILL_DIR"/references/gauntlet-*.md
grep -q 'Always include the required core sections' "$WORK_SKILL_DIR"/references/gauntlet-*.md
grep -q 'Omit optional sections when they are irrelevant' "$WORK_SKILL_DIR"/references/gauntlet-*.md
grep -q 'React and VS Code emphasize summary/description plus exact testing' "$WORK_SKILL_DIR"/references/gauntlet-*.md
! grep -q 'Small PR shortcut' "$WORK_SKILL_DIR"/references/gauntlet-*.md
