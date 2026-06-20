# Work Sync Strategy

`work sync` keeps a worktree current with its base branch.

## Default

- Use rebase when there is no open PR.
- Use merge when an open PR exists, because rebasing rewrites history and can disrupt review context.
- Respect explicit `--rebase` or `--merge`.

## Checks

1. Detect current branch.
2. Detect default base branch from repo config, or `main`.
3. Fetch the base branch.
4. Detect open PR with `gh api`, for example `gh api "repos/$ORG/$REPO/pulls" --jq ".[] | select(.head.ref == \"$BRANCH\" and .state == \"open\")"`.
5. Stash dirty changes only when needed.
6. Rebase or merge.
7. Restore stash.
8. Report conflicts and ahead/behind state.

## Commands

```bash
git fetch origin "$BASE"
git rebase "origin/$BASE"
git merge --no-ff "origin/$BASE"
```

Use the merge path only when appropriate. Do not create a merge commit silently if the user asked for rebase.
