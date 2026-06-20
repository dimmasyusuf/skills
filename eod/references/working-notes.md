# EOD Working Notes

Use this optional format during collection and verification. Do not include working notes in the final report.

Default scratch location for a projectless agent thread:

```text
work/eod/
```

Suggested files:

```text
work/eod/date.json
work/eod/facts.jsonl
work/eod/verification-queue.jsonl
work/eod/verified-github.jsonl
work/eod/ai-news.json
work/eod/final.txt
```

## Fact Shape

Write one JSON object per fact:

```json
{
  "source": "agent_session|current_thread|local_git|github|gmail|calendar|memory|discord|ai_news",
  "time": "2026-06-13T13:01:12+07:00",
  "topic": "short topic",
  "summary": "what happened",
  "evidence": ["command, file, thread, message, or connector evidence"],
  "links": ["https://github.com/example-org/example-app/pull/2683"],
  "verification_needed": [
    {"repo": "example-org/example-app", "type": "pr", "number": 2683, "claim": "open polish PR"}
  ],
  "confidence": "high|medium|low"
}
```

## Verification Queue Shape

Write one JSON object per PR or issue candidate:

```json
{
  "repo": "example-org/example-app",
  "type": "pr",
  "number": 2683,
  "source": "agent_session",
  "claim": "polish PR updated today"
}
```

## Verified GitHub Shape

Write one JSON object per verified PR or issue:

```json
{
  "repo": "example-org/example-app",
  "type": "pr",
  "number": 2683,
  "title": "fix(product): polish inbox and composer",
  "state": "open",
  "merged": false,
  "reviewDecision": "APPROVED",
  "checks": "passing|failing|pending|unknown",
  "url": "https://github.com/example-org/example-app/pull/2683"
}
```

## Final Check

Before delivery, save the report body or fenced report to `work/eod/final.txt` when useful and run:

```bash
${EOD_SKILL_DIR:-$HOME/.agents/skills/eod}/scripts/eod-lint.sh work/eod/final.txt
```

Use `--allow-discord` only for explicit `eod discord` mode.
