# Gmail and Calendar Source

Use this module for notification, assignment, meeting, and handoff context.

## Gmail

Use the Gmail connector when available. Search the user's configured local day:

```text
after:YYYY/MM/DD -category:promotions -category:social
```

Prioritize:

- GitHub notifications
- team-domain mail
- assignments
- approval or review notices
- release alerts
- billing, deploy, or access messages that affected engineering work

Skip:

- marketing emails
- social notifications
- stale assignments that GitHub no longer confirms
- personal mail unrelated to work

Every GitHub item found in Gmail must be added to the verification queue and checked with `gh`.

## Calendar

Use the Calendar connector when available. Query the user's configured local day across relevant calendars.

Capture:

- meetings that explain the shape of the day
- handoffs
- release windows
- focus blocks that explain why work was batched or delayed
- direct follow-up obligations

Do not mention meetings as filler. Include them only when they explain work, blockers, review context, or tomorrow items.

## Connector Gaps

If Gmail or Calendar tools are unavailable, do not stop the report. Mark that source as unavailable in the working notes and continue with agent sessions, local git, GitHub, memory, and AI news.
