## Sync

Use for `work sync [branch] [--rebase|--merge]`.

Helper:

```bash
"$WORK_SKILL_DIR/scripts/work-sync.sh" [issue-id|branch|path] [--rebase|--merge]
```

Default strategy:

- Rebase if there is no open PR.
- If an open PR exists, try fast-forward merge first.
- Create a merge commit only when the user passed explicit `--merge`.
- Respect explicit `--rebase` or `--merge`.

Flow:

1. Detect current or requested branch.
2. Detect base branch from `origin/HEAD`, defaulting to `main` only when remote metadata is unavailable.
3. Check for dirty changes. Stash only when needed and restore afterward.
4. Fetch base.
5. Apply strategy.
6. Report conflicts, restored stash state, and ahead/behind summary.

See `references/guide-rebase-vs-merge.md`.

## Resume

Use for `work resume [issue-id|branch]`.

Helper:

```bash
"$WORK_SKILL_DIR/scripts/work-resume.sh" [issue-id|branch|path]
```

Flow:

1. List worktrees under `$WORKSPACE_ROOT/.worktrees`.
2. If there is exactly one, use it.
3. With an argument, match issue id or branch substring.
4. Otherwise ask the user to choose.
5. Print path, branch, issue state, PR state, dirty count, and next recommended action.

## Standup

Use for `work standup`.

Helper:

```bash
"$WORK_SKILL_DIR/scripts/work-standup.sh"
```

Gather:

- Git commits by the user's configured email in the last 36 hours.
- PRs opened, reviewed, approved, merged, or waiting.
- Active worktrees and dirty state.
- Issues assigned to the user.
- Blockers: open PRs not updated in 24 hours, failing checks, conflicts, or waiting reviews.

Output a short standup with: yesterday, today, blockers.

## Cleanup

Use for `work cleanup [branch]`.

Helper:

```bash
"$WORK_SKILL_DIR/scripts/work-cleanup.sh" [issue-id|branch|path]
```

Hard rule: never remove a worktree while its issue is open.

Flow:

1. Detect candidate worktrees.
2. Resolve issue id from branch name.
3. Verify issue state with `gh api "repos/$ORG/$REPO/issues/$ISSUE"`.
4. If issue is open, keep the worktree.
5. If issue is closed, remove the worktree.
6. Delete the local branch only when the PR merged.
7. Run `git worktree prune`.
8. Report what was removed and what was kept.

The user handles any local merge before cleanup.

## List

Use for `work list`.

Helper:

```bash
"$WORK_SKILL_DIR/scripts/work-list.sh"
```

Output columns:

```text
REPO  BRANCH  ISSUE  PR  DIRTY  AHEAD/BEHIND  PATH
```

Issue state determines cleanup eligibility. Closed issues are eligible. Open issues are locked.
