# EOD Source Orchestration

This is the source dispatcher for the `eod` skill. Keep one public `$eod` skill and use these references as internal source modules.

Run independent collectors in parallel where possible, then merge, verify, and compose.

## Mode Source Matrix

| Source | Full default | Quick | Sources diagnostic | Discord mode | Rewrite |
|---|---:|---:|---:|---:|---:|
| Date | yes | yes | yes | yes | yes |
| Agent sessions | yes | yes | yes | yes | no |
| Current conversation | yes | yes | yes | yes | yes |
| Local git | yes | yes | yes | yes | no |
| GitHub | yes | yes | yes | yes | verify refs only |
| Gmail | yes | no | yes | yes | no |
| Calendar | yes | no | yes | yes | no |
| Memory | yes | yes | yes | yes | no |
| Discord | no | no | no | yes | no |
| AI news | yes | yes | no, unless asked | yes | yes |

Discord is not part of the default source order. Only inspect Discord when the user explicitly asks to include Discord context for that EOD.

## Source Modules

Load only the modules needed for the selected mode:

| Module | Purpose |
|---|---|
| `references/source-codex.md` | Agent session history and current thread, including Codex history when available |
| `references/source-local-git.md` | Local repo, worktree, branch, and commit state |
| `references/source-github.md` | Current GitHub truth and PR/issue verification |
| `references/source-mail-calendar.md` | Gmail notifications and Calendar context |
| `references/source-memory.md` | Memory enrichment and verification boundaries |
| `references/source-ai-news.md` | Exactly one current AI or developer-tooling item |
| `references/working-notes.md` | Optional JSONL working note format |
| `references/discord-passes.md` | Optional Discord pass only when explicitly requested |

## Collector Output Shape

For each source, capture compact facts in this shape before merging:

```text
source:
time:
topic:
evidence:
links:
verification_needed:
confidence:
```

Use `verification_needed` for PRs, issues, branches, release notes, deployments, and unclear source claims.

For dense days, use `references/working-notes.md` and write facts as JSONL before composing.

## Verification Queue

Create one queue of candidate PRs and issues before composing:

```text
repo:
type: pr|issue
number:
source:
claim:
```

Verify each item with GitHub before inclusion:

```bash
gh pr view <number> --repo <owner/repo> --json number,title,state,merged,reviewDecision,statusCheckRollup,url
gh issue view <number> --repo <owner/repo> --json number,title,state,assignees,labels,url
```

Trust current GitHub state over agent sessions, Gmail, Calendar, memory, notes, and optional Discord context. Drop stale items.

## Merge Rules

- Deduplicate by PR, issue, repo, branch, worktree, or topic.
- Prefer current GitHub state over historical notifications.
- Prefer local git state for uncommitted work.
- Prefer current conversation for active-thread changes.
- Use session history for narrative, command evidence, files touched, and verification outcomes.
- Use Gmail and Calendar only when they explain assignments, review state, meetings, blockers, or handoffs.
- Use memory as enrichment, not authority.
- Keep tomorrow items concrete: merge, review, follow up, test, deploy, unblock.

## Exclusions

Skip:

- telemetry and cache files
- package caches
- browser history
- unrelated personal notifications
- marketing emails
- stale assignments that GitHub no longer confirms
- old sessions outside today's configured local date
