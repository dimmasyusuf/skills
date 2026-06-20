---
name: "work"
description: "Use when the user asks the AI agent to start, verify, sync, resume, list, clean up, pair, or summarize GitHub issue work."
---

# Work - AI Agent Issue Workflow

Run a reusable GitHub issue workflow inside the AI agent: pick or resolve a
GitHub issue, create or reuse an isolated worktree, install the project, run a
pre-work gauntlet, produce a phased checklist, verify changes, and prepare a
draft commit message. The user commits, pushes, merges, and opens PRs manually
unless they explicitly ask the AI to do one of those operations.

## Invocation

This is a skill for any AI agent. Invoke it by natural language or a skill chip.

Preferred prompts: `use the work skill`, `work verify`, `work sync`, `work list`, `work resume`, `work standup`.
Announce at start: "Using the work skill - pre-work checks first, then implementation handoff."
## Modes

| Prompt | Mode |
|---|---|
| `use the work skill` | Pick an assigned open issue and start work |
| `use the work skill for issue #123` | Start work on an explicit issue |
| `work pair <id-a> <id-b>` | Create paired worktrees for related issues |
| `work verify` | Run the post-work verification gauntlet |
| `work sync [branch] [--rebase|--merge]` | Refresh a worktree from its base branch |
| `work resume [issue-id|branch]` | Return to an existing worktree |
| `work standup` | Summarize active worktrees and recent GitHub activity |
| `work cleanup [branch]` | Remove worktrees only when their issues are closed |
| `work list` | Show active worktrees, issue state, PR state, and drift |

## Hard Rules

- Keep this skill project-neutral. Put private organization names, repository
  names, internal CLI commands, personal paths, and environment setup hooks in
  local uncommitted config, not in this repository.
- Do not run `git commit`, `git commit --amend`, `git push`, `git merge` when it creates a merge commit, or `gh pr create` unless the user explicitly asks for that operation in the current turn.
- Do not invoke any automation that commits, pushes, merges, or opens PRs as a side effect.
- Never remove a worktree while its issue is still open.
- After a start-work issue is selected or resolved, rename the current session before creating or reusing the worktree.
- New issue worktrees must be cut from the freshly fetched remote base, never from local `main` or the current `HEAD`.
- GitHub Projects status updates are read-safe by default. Do not mutate a project item unless `WORK_PROJECT_WRITE=1` and project IDs are configured.
- Always use native Superpowers skills for the matching work stage. If a required Superpowers skill is not visible, search for it, report the gap, and follow `references/guide-superpowers.md`.
- Always use `gh api` or `gh api graphql` for current GitHub issue, PR, and Projects state. Do not rely only on `gh issue`, `gh pr`, notifications, memory, or web pages for GitHub truth.
- Always inspect local installed dependency artifacts for touched external packages when present, then use Context7 or official docs for current/version-sensitive API behavior, and do a bounded public web search for relevant upstream issues, changelogs, or service status. If a source is not applicable, say why.
- Surface ambiguous choices only when there are two or more valid options and choosing one would materially change the work.
- Auto-pick when exactly one valid option exists.

At the end of `work verify`, prepare a draft conventional commit message and a
draft PR title/body for the user. Do not create the commit or PR unless the user
explicitly asks in the current turn.

```text
<type>(<scope>): <subject>

<body: why this changed, behavior impact, and verification summary>

Closes #<issue-id>
```

Line limit: 100 characters per line. No co-author footer. No emoji.

Every PR draft should include the industry-standard core used across serious
large-project review workflows: summary, why/context, what changed, how to
test, and issue closure. Dynamically add conditional sections such as evidence,
risk, rollback, security/data, performance/observability, release notes,
screenshots/recordings, breaking changes/migration, dependencies,
deployment/operations, compatibility, follow-ups, and reviewer notes when
relevant. Omit irrelevant optional sections instead of padding the PR with
`N/A`. See `references/gauntlet-*.md`.

## Shared Setup

Set `WORK_SKILL_DIR` when the skill is installed somewhere other than the
default portable skill home:

```bash
WORK_SKILL_DIR="${WORK_SKILL_DIR:-$HOME/.agents/skills/work}"
source "$WORK_SKILL_DIR/scripts/lib.sh"
work_init || exit 1
```

`work_init` detects the workspace, repo scope, GitHub org, sources config only when a config file already exists, verifies `gh` authentication, and checks `jq`.

For deterministic start-work shell orchestration, use:

```bash
"$WORK_SKILL_DIR/scripts/work-start.sh" --resolve-only
"$WORK_SKILL_DIR/scripts/work-start.sh" --resolve-only "<issue-ref>"
"$WORK_SKILL_DIR/scripts/work-start.sh"
"$WORK_SKILL_DIR/scripts/work-start.sh" "<issue-ref>"
```

Run `--resolve-only` first, rename the session with the native
`set_thread_title` tool, then run the full command to create or reuse the
worktree. With no issue ref, the script lists assigned open issues and
auto-picks only when exactly one issue is valid in the current workspace scope.

## Start Work

1. Resolve the issue.
   - With no issue argument, query assigned open issues using `work_list_assigned_issues`, which calls `gh api search/issues`.
   - With an issue argument, accept `123`, `#123`, `GH-123`, or a GitHub URL, normalize with `work_normalize_issue_ref`, and resolve the owning repo.
   - Reject pull requests returned by GitHub's Issues API. PR numbers are not valid `work` issue refs.
2. Rename the current session immediately after the issue is known.
   - Format: `<repo>#<issue>: <lowercase issue title>`.
   - Example: `example-app#2535: fix login redirect loop`.
   - Compute it with `work_session_title "$REPO" "$ISSUE" "$TITLE"`.
   - Search for the `set_thread_title` thread tool with `tool_search`, then call it with `threadId="${GEMINI_THREAD_ID:-$CODEX_THREAD_ID}"` and `title="$SESSION_TITLE"` when both are available.
   - If the title tool or current agent thread ID is unavailable, state the intended title and continue.
   - Do not merely suggest a title to the user.
3. Optionally move the issue to In Progress with `work_project_move_in_progress "$ISSUE_URL"`.
   - By default this returns `skipped` and makes no project mutation.
   - It may update a project item only when `WORK_PROJECT_WRITE=1` and ID-based `WORK_PROJECT_*` values are configured.
   - It uses `gh api graphql`, not `gh project`, so the API path is explicit and testable.
   - It searches up to `${WORK_PROJECT_ITEM_LIMIT:-200}` project items in GraphQL pages of at most 100.
   - It reports `not-found`, `list-error`, or `edit-error` without creating project items or blocking worktree setup.
4. Determine branch type from exact issue-label names with `work_label_to_type`. Use `WORK_LABEL_TO_TYPE` for repo-specific label conventions.
5. Slug the issue title and create branch `<type>/<issue>-<slug>`.
6. Use worktree path `$WORKSPACE_ROOT/.worktrees/<repo>/<issue>-<slug>`.
7. Ensure `.worktrees/` is in the workspace `.gitignore`.
8. Create or reuse the worktree.
   - If the target worktree path or local branch already exists, reuse it without requiring a fetch.
   - Before creating a new worktree, fetch the detected default branch from `origin`.
   - Create the branch from `origin/<default-branch>` by using `work_create_worktree "$REPO_DIR" "$WORKTREE" "$BRANCH"`.
   - Do not use bare `git worktree add "$WORKTREE" -b "$BRANCH"` because it can branch from stale local `main` or the current `HEAD`.
9. Detect package manager and install dependencies when needed.
10. Run repo setup with `work_run_repo_hooks "$REPO"`.
   - Safety hooks run before env hooks.
   - Built-in hooks are generic only. Define project-specific setup in local
     config and never print secret values.
   - If it prints `no-env-hook`, surface setup scripts, README setup notes, and `.env.example` keys.
11. Run the pre-work gauntlet from `references/gauntlet-00-pre-work.md`.
12. Output a phased checklist: Explore, Plan, Implement, Verify, Ship, Review, Cleanup.

Detailed mode behavior lives in `references/modes-*.md`.

## Verify Work

Run from inside an active worktree. Follow `references/gauntlet-*.md`.

Required checks:

1. Changed files and diff summary.
2. Current GitHub state via `gh api`.
3. Local dependency and `node_modules` inspection for changed dependencies.
4. Context7 or official docs for every touched external library/API.
5. Bounded public web search for relevant upstream issues, changelogs, or service status.
6. New-library inspection for dependencies added in the diff.
7. Tests.
8. Type check.
9. Lint.
10. Duplicate-function scan when relevant.
11. Senior engineer quality gate: existing utility reuse, simplification, and domain-role review.
12. Code review using available review tools or direct review.
13. Security review using available Security tools.
14. Superpowers verification-before-completion pass.
15. Draft conventional commit message and comprehensive PR title/body.

## Sync, Resume, Standup, Cleanup, List

- `work sync`: use `scripts/work-sync.sh [issue-id|branch|path] [--rebase|--merge]`. Rebase by default. For open PRs, try fast-forward merge first and require explicit `--merge` before creating a merge commit.
- `work resume`: use `scripts/work-resume.sh [issue-id|branch|path]` to find the target worktree path.
- `work standup`: use `scripts/work-standup.sh` to summarize recent commits, active worktrees, and assigned issues.
- `work cleanup`: use `scripts/work-cleanup.sh [issue-id|branch|path]`; it removes only worktrees whose issue is closed and deletes local branches with `git branch -d` only when the PR merged.
- `work list`: use `scripts/work-list.sh` to print repo, branch, issue state, PR state, dirty count, and ahead/behind base.
- `work verify`: use `scripts/work-verify.sh` for deterministic preflight output, then follow `references/gauntlet-*.md`.
- `work pair`: use `scripts/work-pair.sh <issue-a> <issue-b>` for paired worktree setup.

## Optional Config


Common extension points:

- `WORK_ORG`
- `WORK_PROJECT_*`
- `work_env_setup__<repo>()`
- `work_safety_check__<repo>()`
- `WORK_LABEL_TO_TYPE`
- `WORK_DEFAULT_BRANCH`

## Prerequisites

1. `gh` authenticated with `gh auth login`.
2. `jq` installed.
3. Expected plugins/connectors for the full flow: GitHub, Context7, CodeRabbit or code review, Security tools, Browser, Build Web Apps, Expo, Twilio Developer Kit, and native Superpowers. Always attempt the relevant plugin/skill first; if it is unavailable, report the gap and run the closest local fallback.

## References

- Mode details: `references/modes-*.md`
- Project-neutral configuration: `references/guide-project-config.md`
- Native Superpowers composition: `references/guide-superpowers.md`
- Local skills list and composition guidance: `references/guide-skills-list.md`
- Trigger routing evals: `references/guide-trigger-prompts.md`
