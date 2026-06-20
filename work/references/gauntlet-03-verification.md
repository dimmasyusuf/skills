## 12. Security Review

Use native Security or direct review every time. Escalate especially when the diff touches:

- authentication
- authorization
- secrets
- payments
- webhooks
- file uploads
- data deletion
- external network calls

## 13. Acceptance Criteria

Map the issue acceptance criteria to evidence from the diff and commands. If no explicit criteria exist, derive the expected behavior from the issue title/body and changed code.

## 14. Final Verification Gate

Before claiming completion, run a final verification pass and produce an
evidence ledger:

- check that requested behavior is implemented
- check that tests/lint/typecheck status is known
- check that no unrelated changes were made
- check that no user-owned changes were reverted
- check that risks and skipped checks are explicit
- log intercepted bugs using `work-telemetry.sh --type "bug_intercept" --severity "high" --message "<description>"`

Use `superpowers:verification-before-completion`. If it is missing, search for it, follow `references/guide-superpowers.md`, and report the gap.
If the changes affect a frontend or web surface, invoke the `web-quality-audit` skill to prevent performance, accessibility, and Core Web Vitals regressions.

```text
Evidence ledger:
Superpowers:
GitHub API:
Local dependency artifacts:
Context7 or official docs:
Public web search:
Plugins/skills attempted:
Senior role lens:
Existing utility reuse:
Simplification:
Tests:
Type check:
Lint:
Review:
Security:
Skipped or not applicable:
```

Keep each line concrete. Include exact `gh api` endpoints or GraphQL operation
names, package files inspected, Context7 library IDs or official-doc URLs, web
URLs, plugin or skill names, commands with exit status, review findings or
blockers, security result, and explicit skip reasons.

