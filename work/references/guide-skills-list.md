# Local Skills List

Default local installed skill home: `$HOME/.agents/skills`.

Refresh this list with:

```bash
work/scripts/util-list-skills.sh
```

## Issue Work Core

- `work` - start, verify, sync, resume, list, cleanup, pair, and summarize GitHub issue work.
- `issue` - scope, preview, and create GitHub issues.
- `commit-helper` - commits and PRs outside issue-specific work.
- `pr-review-loop` - PR comments, CodeRabbit, failing CI, and review follow-up.
- `pr-splitter` - split large changes into smaller PRs.
- `session-report` - concise current-session status and handoff.

## Setup And Tooling

- `setup-doctor`
- `config-manager`
- `plugin-auditor`
- `mcp-manager`
- `mcp-server-builder`
- `hook-manager`
- `rules-manager`
- `skill-migrator`
- `thread-manager`
- `loop-automation`

## Code Work

- `codebase-map`
- `code-modernization`
- `context7-mcp`
- `dependency-manager`
- `testing-debugging`
- `language-server-manager`
- `database-manager`
- `deployment-manager`
- `observability-triage`
- `api-workbench`
- `agent-builder`

## Artifacts And Utilities

- `artifact-canvas`
- `playwright`
- `pdf`
- `hatch-pet`
- `chronicle`
- `eod`

## Micro-Skills (github/awesome-copilot)

The active local skill set keeps only the `github/awesome-copilot` micro-skills
that are referenced by this `work` workflow. Unused awesome-copilot skills were
archived out of the local skill home to keep skill routing focused.

- **Testing & QA:** `playwright-generate-test`, `webapp-testing`, `eval-driven-dev`, `doublecheck`, `breakdown-test`
- **Architecture & Planning:** `excalidraw-diagram-generator`, `architecture-blueprint-generator`, `create-architectural-decision-record`, `cloud-design-patterns`, `technology-stack-blueprint-generator`, `breakdown-epic-arch`, `folder-structure-blueprint-generator`, `project-workflow-analysis-blueprint-generator`, `prd`
- **Optimization:** `postgresql-optimization`, `sql-optimization`, `multi-stage-dockerfile`, `github-actions-efficiency`
- **Refactoring:** `refactor-method-complexity-reduce`, `memory-merger`, `refactor`, `review-and-refactor`, `refactor-plan`
- **Process & Context:** `conventional-commit`, `create-readme`, `documentation-writer`, `write-coding-standards-from-file`, `editorconfig`, `breakdown-plan`, `breakdown-feature-implementation`, `gen-specs-as-issues`, `first-ask`, `what-context-needed`, `context-map`, `remember`
- **Quality & Safety:** `audit-integrity`, `diagnose`, `quality-playbook`, `security-review`, `sql-code-review`, `threat-model-analyst`, `secret-scanning`
- **Deployment & Operations:** `devops-rollout-plan`
- **AI Orchestration & Autonomy:** `ai-team-orchestration`, `structured-autonomy-plan`, `structured-autonomy-implement`

## Other Referenced Local Skills

These active local skills are referenced by `work` but are not part of the
retained `github/awesome-copilot` subset:

- `tdd`
- `systematic-debugging`
- `emil-design-eng`
- `improve-codebase-architecture`
- `caveman`
- `web-quality-audit`
- `workflow-orchestration-patterns`

## Composition Guidance

Prefer the narrowest matching skill:

- New issue before coding: use `issue`, then `work`.
- Existing issue implementation: use `work`.
- Commit/PR without issue workflow: use `commit-helper`.
- Current thread recap: use `session-report`, not `eod`, unless the user asks for EOD.
- Debugging app code: use `testing-debugging` inside or before `work`.
- Simplifying changed code or removing duplication during verify: use `code-modernization`, then CodeRabbit/code review; if `code-simplifier` is visible, use it too.
- Skill edits: attempt `superpowers:writing-skills`; use `skill-migrator` for ports when applicable.
- For hyper-specific tasks (e.g., drawing an architecture diagram or optimizing a specific DB query), delegate to the retained `github/awesome-copilot` micro-skills. Restore or reinstall archived specialty skills only when the task genuinely needs them.

For richer issue work, also attempt the relevant plugin skills from GitHub, CodeRabbit, native Security, Build Web Apps, Expo, Twilio Developer Kit, Browser, Jam, Product Design, Supabase/Postgres, and Google Workspace. See `references/guide-skill-reference.md` for the selection matrix.
