# Agent Session Source

Use this module for AI-agent session history and the current active conversation.
The bundled collector currently supports Codex session archives when they are
available locally.

## Inputs

Primary files:

```text
~/.codex/session_index.jsonl
~/.codex/archived_sessions/*.jsonl
```

The current thread may not be archived yet. Use visible conversation context for current-thread work.

## Helper

When available, run:

```bash
${EOD_SKILL_DIR:-$HOME/.agents/skills/eod}/scripts/eod-codex-sessions.sh
${EOD_SKILL_DIR:-$HOME/.agents/skills/eod}/scripts/eod-codex-sessions.sh --json
```

The helper lists sessions updated today in the configured timezone and prints likely archive paths. Open relevant archives for detail.

## Extract

Capture:

- thread name
- session id when present
- updated time converted to the configured timezone
- cwd or project path
- first user prompt or task intent
- files edited
- commands run
- tests, lint, typecheck, build, and review commands
- PR and issue numbers
- decisions, blockers, and verification outcomes

## Current Conversation

Include active-thread work when it happened today:

- user requests
- implemented changes
- files changed
- commands run
- verification status
- unresolved blockers

Do not invent hidden state. If current-thread artifacts are not available, rely on local git and GitHub.

## Verification Notes

Any PR or issue number found in agent session history must be added to the verification queue in `references/sources.md`.
