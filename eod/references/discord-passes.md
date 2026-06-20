# Optional Discord Scan Strategy

Do not use this file during the default EOD flow. Use it only when the user explicitly asks to include Discord context for the EOD.

Prefer a connector if available. Otherwise use Computer Use with the Discord desktop app.

## Pass 1 - Mentions

Search for today's mentions of the user. Capture direct asks, reviews, blockers, approvals, and support requests.

## Pass 2 - User Messages

Search for messages from the user today. Capture updates, decisions, links, and status posts.

## Pass 3 - Always-Scan Channels

Read optional channel queries from:

```text
skills/eod/config/discord-channels.txt
```

Each non-comment line is one channel or search query.

Capture only work-relevant context. Do not include casual chat unless it materially explains the day.

## Verification

Any PR, issue, branch, release, or deployment mentioned in Discord must be verified with GitHub or local git before inclusion.
