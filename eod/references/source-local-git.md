# Local Git Source

Use this module for local repos, worktrees, branches, commits, and uncommitted work.

## Scope

Inspect relevant workspaces under:

```text
$HOME/projects
```

Prioritize configured repos and paired `.worktrees`:

```text
example-org/example-app
example-org/example-api
```

## Helper

When available, run:

```bash
${EOD_SKILL_DIR:-$HOME/.agents/skills/eod}/scripts/eod-local-git.sh
${EOD_SKILL_DIR:-$HOME/.agents/skills/eod}/scripts/eod-local-git.sh --json
```

The helper prints repo path, branch, remote, status count, changed files, and commits authored today.

## Manual Commands

From each relevant repo or worktree:

```bash
git status --short
git log --since="$(TZ=${EOD_TZ:-${TZ:-UTC}} date +%Y-%m-%d) 00:00" --author="$(git config user.email)" --oneline
git branch --show-current
git remote get-url origin
git rev-list --left-right --count @{upstream}...HEAD
```

If no upstream exists, skip ahead/behind and record that the branch has no upstream.

## Extract

Capture:

- repo and worktree path
- active branch
- remote owner/repo
- staged and unstaged files
- untracked files that look intentional
- commits authored today, including SHAs and subjects
- ahead/behind state when upstream exists
- related issue or PR number inferred from branch names or commit subjects

## Verification Notes

Local git is authoritative for uncommitted work and unpushed commits. GitHub remains authoritative for PR and issue state.
