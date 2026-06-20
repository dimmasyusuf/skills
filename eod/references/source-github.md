# GitHub Source

Use this module for current PR, issue, review, check, and assignment state.

GitHub is the current-state authority for PRs and issues.

## Helper

When available, run:

```bash
${EOD_SKILL_DIR:-$HOME/.agents/skills/eod}/scripts/eod-gh-summary.sh
${EOD_SKILL_DIR:-$HOME/.agents/skills/eod}/scripts/eod-gh-summary.sh --json
```

The helper prints recent authored PRs, assigned issues, review requests, and recent authored commits when `gh` is authenticated.

## Direct Checks

Check:

- PRs authored by the user and updated today
- PRs assigned to or requesting review from the user
- issues assigned to the user
- review comments and approvals
- CI/check state
- commits authored today on configured repositories

Useful commands:

```bash
gh search prs --owner "$EOD_GH_ORG" --author @me --updated ">=$(TZ=${EOD_TZ:-${TZ:-UTC}} date +%Y-%m-%d)" --json repository,number,title,state,url,updatedAt
gh search issues --owner "$EOD_GH_ORG" --assignee @me --state open --json repository,number,title,state,url,updatedAt
gh search prs --owner "$EOD_GH_ORG" --review-requested @me --state open --json repository,number,title,state,url,updatedAt
```

## Required Verification

For every PR or issue found outside GitHub, run one of:

```bash
gh pr view <number> --repo <owner/repo> --json number,title,state,merged,reviewDecision,statusCheckRollup,url
gh issue view <number> --repo <owner/repo> --json number,title,state,assignees,labels,url
```

Record:

- title
- current state
- merged status for PRs
- review decision for PRs
- check state for PRs
- assignees and labels for issues
- canonical URL

## Drop Rules

Drop an item when:

- GitHub says it no longer exists
- it is closed and unrelated to today's work
- it was only a stale notification
- it cannot be tied to the user's work, assignment, review, or blocker
