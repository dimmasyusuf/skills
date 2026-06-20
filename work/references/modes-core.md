# Work Mode Implementations

These modes are invoked by natural-language prompts in the AI agent, such as `work verify` or `use the work skill for issue #123`.

## Shared Shell Context

```bash
WORK_SKILL_DIR="${WORK_SKILL_DIR:-$HOME/.agents/skills/work}"
source "$WORK_SKILL_DIR/scripts/lib.sh"
work_init || exit 1
```

When running inside the source repo before sync, `WORK_SKILL_DIR` may be the
local source checkout, for example `$HOME/projects/skills/work`.

## Start Work

Use for:

- `use the work skill`
- `use the work skill for issue #123`
- `work on issue #123`

Flow:

1. Resolve the issue.
   - No argument: query assigned open issues under `$ORG`.
   - Explicit argument: normalize `123`, `#123`, `GH-123`, or URL with `work_normalize_issue_ref`.
   - Reject pull requests returned by the Issues API; PR numbers should route through PR/review workflows.
2. If there is exactly one match, use it. If multiple valid matches exist, ask the user to choose.
3. Read issue title, body, labels, repo, and linked issues.
4. Rename the current session before creating or reusing the worktree.
5. Call `work_project_move_in_progress "$ISSUE_URL"`.
   - Treat `skipped` and `not-found` as non-blocking.
   - Only `WORK_PROJECT_WRITE=1` allows project mutation.
6. Infer branch type from labels with `work_label_to_type`.
7. Create slug with `work_slug`.
8. Branch: `<type>/<issue>-<slug>`.
9. Worktree: `$WORKSPACE_ROOT/.worktrees/<repo>/<issue>-<slug>`.
10. Ensure `.worktrees/` is gitignored.
11. Create or reuse the worktree from the freshly fetched remote base.
12. Run install/setup.
13. Run repo hooks with `work_run_repo_hooks "$REPO"`.
14. Run the pre-work gauntlet.
15. Print a concise checklist for implementation and verification.

Preferred orchestration command:

```bash
"$WORK_SKILL_DIR/scripts/work-start.sh" --resolve-only
"$WORK_SKILL_DIR/scripts/work-start.sh" --resolve-only "$ISSUE_REF"
"$WORK_SKILL_DIR/scripts/work-start.sh"
"$WORK_SKILL_DIR/scripts/work-start.sh" "$ISSUE_REF"
```

Run `--resolve-only` first. It resolves the issue, branch, worktree path, and
session title without touching GitHub Projects or creating a worktree. The AI
then owns the native thread-title tool call. After the session is renamed, run
the full script to handle read-safe project status, remote-base worktree
creation, install, and repo hooks. With no issue ref, `work-start.sh` lists
assigned open issues and auto-picks only when exactly one issue is valid in the
current workspace scope.

Useful commands:

```bash
work_list_assigned_issues
gh api "repos/$ORG/$REPO/issues/$ISSUE"
work_project_move_in_progress "$ISSUE_URL"
work_create_worktree "$REPO_DIR" "$WORKTREE" "$BRANCH"
HOOK_RESULT="$(work_run_repo_hooks "$REPO")" || exit 1
[ -n "$HOOK_RESULT" ] && echo "$HOOK_RESULT"
[ "$HOOK_RESULT" = "no-env-hook" ] && echo "Surface README setup notes and .env.example keys."
```

`work_create_worktree` fetches the detected default branch from `origin`, then creates the new issue branch from that remote-tracking ref. It reuses an existing worktree path or local branch when present. Do not create new issue worktrees from local `main` or from the current `HEAD`.

Session title:

```bash
SESSION_TITLE="$(work_session_title "$REPO" "$ISSUE" "$TITLE")"
```

Rename with the native thread-title tool:

- Use `tool_search` to expose `set_thread_title`, then call it with `threadId="${GEMINI_THREAD_ID:-$CODEX_THREAD_ID}"` and `title="$SESSION_TITLE"`.
- If `CODEX_THREAD_ID`/`GEMINI_THREAD_ID` or the title tool is unavailable, report `Session title should be: <title>` and continue.

Do not merely suggest a title after the checklist. The rename belongs between
`work-start.sh --resolve-only` and the full `work-start.sh` run.

Project status:

- `work_project_move_in_progress` is best-effort and read-safe unless `WORK_PROJECT_WRITE=1`.
- It uses `gh api graphql`, GitHub Project IDs, fetches up to `${WORK_PROJECT_ITEM_LIMIT:-200}` items in pages of at most 100, and returns `skipped`, `not-found`, `list-error`, `edit-error`, or `updated`.
- Do not call `gh project item-add` from this skill; missing project items are reported, not created.

## Pair Work

Use for paired frontend/backend or app/API issues.

Helper:

```bash
"$WORK_SKILL_DIR/scripts/work-pair.sh" "$ISSUE_REF_A" "$ISSUE_REF_B"
```

Flow:

1. Resolve both issues independently.
2. Create one worktree per repo.
3. Detect local service ports and environment variables.
4. Prefer local service wiring over example port-forwards.
5. Print both worktree paths and the integration checklist.

Each issue remains independently verified and committed by the user.

## Verify

Use for `work verify`.

Run deterministic preflight output first:

```bash
"$WORK_SKILL_DIR/scripts/work-verify.sh"
```

Then run the post-work gauntlet in `references/gauntlet-*.md`. Stop on critical failures. Prepare draft commit and PR messages only after verification passes or after clearly reporting unresolved risks.
