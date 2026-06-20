---
name: "eod"
description: "Use when the user asks the AI agent to write an end-of-day report, Discord EOD, standup summary, daily work wrap-up, or 'what did I do today'. Gathers available agent session history, GitHub activity, local git work, Gmail, Calendar, memory, and one verified current AI/dev-tooling news item, then writes a paste-ready report in the user's lowercase voice."
---

# EOD - AI Agent End-of-Day Report

Generate one narrative report the user can paste into a team chat or daily
update channel. In normal report modes, output only the report inside a single
`txt` fenced code block. No preamble, no closing notes, no tool commentary.

This is a portable AI-agent skill. Invoke it by natural language or a skill chip when the current agent UI provides one.

## Skill Summary

- **Purpose:** turn today's AI-agent-assisted work, GitHub activity, local git state, and team context into one paste-ready EOD.
- **Primary inputs:** available agent session history, current conversation, local repos/worktrees, GitHub, Gmail, Calendar, memory, and one current AI/dev-tooling news item.
- **Output:** a lowercase narrative report with `done:`, `tomorrow`, and `ai:` sections in the exact EOD format. Use masked Markdown links for work URLs, but put the AI source URL on its own bare line.
- **Verification rule:** any PR or issue found outside GitHub must be checked against current `gh` state before inclusion.
- **Discord rule:** do not inspect Discord by default. Only scan Discord when the user explicitly asks to include Discord context.
- **Voice rule:** write as the user, not as the AI agent; no meta-commentary, no source notes, no tool narration.

Preferred prompts:

```text
use the eod skill
write my discord eod
wrap up today
what did i do today
do my standup
eod quick
eod sources
eod discord
eod rewrite
```

If the current agent UI exposes skill chips or `$eod`, either form is acceptable.

Write in the user's requested voice. If no voice is specified, keep it concise,
lowercase, and work-focused.

## Modes

| Prompt | Mode |
|---|---|
| `use the eod skill` | Full default report with available agent sessions, current thread, local git, GitHub, Gmail, Calendar, memory, and AI news. No Discord. |
| `eod quick` | Faster report using available agent sessions, current thread, local git, GitHub, memory, and AI news. Skip Gmail, Calendar, and Discord. |
| `eod sources` | Diagnostic mode. Gather source coverage and verification gaps, but do not compose the final report. |
| `eod discord` or `include discord context` | Full report plus optional Discord scan. Use only when explicitly requested. |
| `eod rewrite` | Rewrite user-supplied notes into the EOD shape. Verify any PR or issue links found in the notes. |

## Hard Rules

- Keep `$eod` as the only public skill. Do not route default work through separate installed micro-skills.
- Use internal references and scripts as source modules, then merge into one report.
- Discord is a destination by default, not a source. Do not inspect Discord unless the user explicitly asks for Discord context.
- GitHub is the authority for PR and issue state. Verify PRs and issues found in agent sessions, Gmail, memory, notes, or optional Discord before inclusion.
- Use `EOD_TZ` when set, otherwise the current shell timezone, for all same-day
  filtering and report headings.
- Do not invent hidden state. If a source is unavailable, continue with available verified sources and avoid pretending it was checked.
- Browse for the AI news item during report generation. Do not rely on stale model memory.
- Use masked Markdown links for work URLs. The only bare URL allowed in the report is the AI source URL on the line after the AI news sentence.
- Write as the user in lowercase. Do not mention source gathering, tools, or the AI agent unless the agent itself was the work being reported.
- For normal report modes, output only one `txt` fenced block.

## Reference Files

Load only when needed:

| File | Load when |
|---|---|
| `references/sources.md` | Source orchestration, mode source matrix, and merge rules |
| `references/source-codex.md` | Agent session and current conversation collection, with Codex history support when available |
| `references/source-local-git.md` | Local repo, worktree, branch, and commit collection |
| `references/source-github.md` | GitHub PR, issue, review, check, and verification collection |
| `references/source-mail-calendar.md` | Gmail and Calendar collection |
| `references/source-memory.md` | Agent memory collection and verification boundaries |
| `references/source-ai-news.md` | Current AI or developer-tooling news collection |
| `references/working-notes.md` | Optional machine-readable working note format |
| `references/discord-passes.md` | Optional Discord scan strategy, only when explicitly requested |
| `references/composition.md` | Structure, voice, and punctuation rules |
| `references/example.md` | Final shape check |

## Helper Scripts

Use helper scripts when available, then inspect and interpret their output:

```bash
EOD_SKILL_DIR="${EOD_SKILL_DIR:-$HOME/.agents/skills/eod}"
"$EOD_SKILL_DIR/scripts/eod-date.sh"
"$EOD_SKILL_DIR/scripts/eod-codex-sessions.sh"
"$EOD_SKILL_DIR/scripts/eod-local-git.sh"
"$EOD_SKILL_DIR/scripts/eod-gh-summary.sh"
"$EOD_SKILL_DIR/scripts/eod-lint.sh" <final-report.txt>
```

For dense days, use `--json` on collector scripts and write their output into `work/eod/` using `references/working-notes.md`.

Scripts are deterministic collectors, not authority by themselves. Verify GitHub state with `gh` before reporting PRs or issues.

## Phase 1 - Date

Use the user's configured local date:

```bash
export EOD_TZ="${EOD_TZ:-$TZ}"
date "+%A, %d %B" | tr '[:upper:]' '[:lower:]'
date +%Y-%m-%d
```

## Phase 2 - Data Gathering

Run independent sources in parallel where possible:

1. Available agent session history, including Codex history under `~/.codex` when present.
2. Current conversation context.
3. Local git activity and worktrees.
4. GitHub issues, PRs, commits, reviews, and checks.
5. Gmail for notifications and assignments, verified with GitHub.
6. Calendar for meeting context.
7. Memory sources available in the current agent.
8. Discord only when explicitly requested.

Load `references/sources.md` for details.

## Phase 3 - Verification

For every PR or issue found outside GitHub, verify current state with `gh pr view` or `gh issue view`. Trust current GitHub state over notifications and session history.

## Phase 4 - Merge

Deduplicate by PR, issue, branch, repo, or topic. Keep the richest version of each work unit:

- Agent sessions: intent, files touched, commands, decisions.
- GitHub: current status and review/check state.
- Git: local WIP, staged changes, unpushed commits.
- Gmail: assignments, feedback, approvals, blockers.
- Calendar: meeting context.
- Memory: prior decisions and narrative enrichment.

## Phase 5 - AI News

Include exactly one verified-today AI or developer-tooling item. Browse the web when generating the report; do not rely on stale model memory.

Prefer official sources, GitHub Blog, OpenAI, Google DeepMind, Hacker News, TLDR AI, Latent Space, and other current dev-tooling sources. Skip pure policy news unless it materially affects engineering work.

## Phase 6 - Compose

Apply `references/composition.md`.

Required skeleton:

```text
<weekday, day month>

done:
<one chronological paragraph using natural time phrases when supported>

tomorrow
- <next item>
- <next item>
- <next item>

ai:
<news>
<source url>
```

Use `done:` on its own line, then one chronological paragraph on the next line. Naturally mention time of day when supported, such as morning, afternoon, later in the day, or evening. Do not use time-of-day labels like `morning:`. Use `tomorrow` without a colon and list next actions with `- `. Do not include a separate `blockers:` section.
Use masked Markdown links for PRs, issues, docs, and work URLs: `[label](url)`. The `ai:` source URL is the only bare URL exception and should not be wrapped in `[source](url)`.

## Phase 7 - Lint

Before delivery, run the final report through:

```bash
"${EOD_SKILL_DIR:-$HOME/.agents/skills/eod}/scripts/eod-lint.sh" <final-report.txt>
```

Use `--allow-discord` only for explicit `eod discord` mode.

## Phase 8 - Deliver

After lint passes, output only:

```txt
...
```

No notes about sources, tools, or limitations unless a limitation belongs inside the report as a blocker.

## Customization

Keep private company context out of this public skill. Configure local defaults
with environment variables instead:

```bash
export EOD_TZ="UTC"
export EOD_GH_ORG="example-org"
export EOD_DEV_ROOT="$HOME/projects"
```

Project names, teammate names, private repository lists, and internal support
channels belong in local notes or ignored config, not in this repository.
