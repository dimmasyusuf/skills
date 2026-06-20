# Related Skills and Plugins

Always attempt the relevant skill or plugin for the current work stage. If it is
not available in the current session, search for it with `tool_search` or
report the gap and continue with the closest local fallback. Do not assume every
plugin is installed.

## Explore

- Episodic Memory for prior decisions.
- Context7 for every touched external library/API/SDK/CLI/cloud-service docs check.
- `gh api` or `gh api graphql` for current issue, PR, check, and project state.
- native Superpowers for the matching work stage; see `references/guide-superpowers.md`.
- Public web search for relevant official announcements, upstream issues, changelogs, and service status.

## Plan

- Superpowers brainstorming or writing-plans for large changes.
- Local project docs and existing implementation patterns.

## Implement

- Test-driven development skill for risky behavior changes.
- Framework-specific skills such as Expo, frontend-design, or OpenAI docs when relevant.
- Browser or Chrome plugins for UI verification.

## Verify

- CodeRabbit or code-review plugin for diff review.
- `code-modernization` for scoped simplification and duplication removal.
- `code-simplifier` or `code-simplify` if a native skill/plugin is visible; otherwise report it unavailable and run the direct simplification review in `references/gauntlet-02-quality.md`.
- native Security for every change; use deeper security skills for sensitive surfaces.
- Duplicate-function scan for shared helper work.
- Verification-before-completion before reporting done.
- Always prefer `superpowers:verification-before-completion` when visible.

## Worthwhile Plugin/Skill Matrix For Project Work

| Surface | Always attempt first | Fallback if missing |
|---|---|---|
| GitHub issue/PR/project truth | `gh api` / `gh api graphql`, GitHub plugin for structured context | local `git` plus direct `gh api` |
| Worktree discipline | `superpowers:using-git-worktrees` | local worktree checks in `scripts/lib/git.sh` |
| Planning and execution | `superpowers:brainstorming`, `superpowers:writing-plans`, `superpowers:executing-plans` | concise local plan/checklist |
| TDD/debugging | `superpowers:test-driven-development`, `superpowers:systematic-debugging`, `testing-debugging` | focused repro plus narrow tests |
| Senior code quality | `code-modernization`, CodeRabbit, `code-simplifier` when visible, domain plugin skills | direct senior-engineer quality gate |
| Web frontend | Build Web Apps skills, `playwright`, Browser/in-app browser | local scripts and screenshots |
| Mobile/Expo | Expo skills: `upgrading-expo`, `native-data-fetching`, `building-native-ui`, `codex-expo-run-actions` | Expo CLI diagnostics and local docs |
| Twilio/product | Twilio Developer Kit skills for messaging, voice, webhooks, reliability, security | installed package docs plus Context7/official docs |
| Backend/API/database | `api-workbench`, `database-manager`, Supabase/Postgres skills when relevant | local schema/docs and targeted tests |
| PR review | CodeRabbit, GitHub `gh-address-comments`, `gh-fix-ci`, `pr-review-loop` | direct diff review and Actions logs via `gh api` |
| Security | native Security `security-diff-scan`, `fix-finding`, `validation`, `threat-model` | direct security checklist |
| UI bug recordings | Jam plugin for recordings/screenshots | manual release notes |
| Product/design QA | Product Design `audit` or `design-qa` when UI behavior is involved | direct browser QA notes |
| Reporting/handoff | `session-report`, `eod` for daily wrap-up | manual summary |

Good future install candidate if the team uses it: the OpenAI skills catalog has
a `sentry` skill; add it only if Sentry is part of the project's release
debugging workflow.

## Tunnels

For instructions on how to handle Dev Tunnels and rewrite `.env` files for public tunnel access, see `references/guide-tunnels.md`.

## Ship

The work skill does not ship automatically. It prepares a draft commit message and reports verification status. The user commits, pushes, and opens PRs unless they explicitly ask the AI to do those steps.

## Cleanup

Use `work cleanup` only after issue closure is verified.

## Hidden Utilities and Telemetry

The work skill includes powerful utilities that are not exposed as primary commands but can be used directly when needed:
- **Telemetry (`scripts/work-telemetry.sh`)**: Logs workflow actions and bugs into a local SQLite database at `~/.agents/work-telemetry.db`. It accepts `--type`, `--severity`, and `--message` flags.
- **Skill Discovery (`scripts/util-list-skills.sh`)**: A utility that safely parses `SKILL.md` frontmatter across your entire configuration directory to list all available installed skills, outputting their name, description, and agent configuration status.
