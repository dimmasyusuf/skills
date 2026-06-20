## 16. Draft Pull Request Message

Prepare, but do not create, a PR title and body. There is no universal
"Conventional PR" standard. Follow the repository's own PR template when one
exists. If no repo template exists, use the section menu below. Always include
the core sections. Add optional sections when they materially help review,
release, operations, security, or QA. Omit irrelevant optional sections instead
of padding the PR with `N/A`.

Title: `<type>(<scope>): <subject>` (Use commit header unless repo conventions differ. Keep short and reviewable.)

Required core body:

```markdown
## Summary

- <what changed>
- <important implementation boundary>
- <docs/tests/config changes>

## Why

<problem, previous behavior, motivation, and user or system impact>

## What Changed

- <code path, behavior, or contract changed>
- <tests or fixtures added/updated>
- <docs, config, migration, or operational changes>

## How To Test

Automated checks:
- [ ] `<exact command>` -> <result>
- [ ] `<exact command>` -> <result>
- [ ] `<exact command>` -> <result>

Manual checks:
- [ ] <scenario, browser/device/API/client, and expected result>
- [ ] <edge case or regression scenario and expected result>

Not run / not applicable:
- [ ] <check> -> <reason>

Closes #<issue-id>
```

Strongly recommended when available:

```markdown
## Evidence

- GitHub API: `<endpoint or GraphQL operation>` -> <result>
- Local dependency artifacts: <files inspected or N/A>
- Context7 / official docs: <library IDs or URLs inspected or N/A>
- Public web search: <URLs or search scope inspected or N/A>
- Screenshots / video / logs: <links, file paths, or N/A>
```

Dynamic section selection:

- UI, visual, mobile, or interaction changes: add `Screenshots / Recordings`
  and `Compatibility`.
- Accessibility-sensitive UI changes: add `Accessibility`.
- API, schema, SDK, config, or user-visible behavior changes: add
  `Breaking Changes / Migration`, `Compatibility`, and `Release Notes`.
- Dependency upgrades or new packages: add `Dependencies`.
- Env vars, migrations, queues, jobs, feature flags, deploy order, or infra:
  add `Deployment / Operations` and `Rollback`.
- Auth, authorization, secrets, PII, payments, deletion, uploads, or network
  calls: add `Security / Privacy / Data`.
- Hot paths, caching, retries, background work, or large data paths: add
  `Performance / Observability`.
- Risky, broad, or release-sensitive changes: add `Risk And Mitigation`,
  `Rollback`, and `Reviewer Checklist`.
- Intentionally deferred work: add `Follow-Ups`.
- Complex tradeoffs or review hotspots: add `Reviewer Notes`.
- Repos with PR labels/kinds: add `PR Type`.

Conditional sections to add when relevant:

```markdown
## PR Type

- <bug|feature|cleanup|documentation|dependency|refactor|test|infra>
- <repo-specific kind/label, if any>

## Risk And Mitigation

Risk: <low|medium|high>

- <specific risk> -> <mitigation or why acceptable>
- <rollback-sensitive area> -> <guardrail>

## Rollback

<exact rollback, disablement, revert, feature-flag, or deploy rollback path>

## Screenshots / Recordings

- Before: <link, image path, video, or reason unavailable>
- After: <link, image path, video, or reason unavailable>
- Notes: <viewport/device/browser/state covered>

## Accessibility

- [ ] Keyboard navigation reviewed.
- [ ] Focus states and focus order reviewed.
- [ ] Screen reader labels/semantics reviewed.
- [ ] Color contrast and reduced-motion behavior reviewed.

## Breaking Changes / Migration

- Breaking change: <yes|no>
- Migration required: <yes|no>
- Previous behavior: <old behavior or contract>
- New behavior: <new behavior or contract>
- Migration path: <steps for users/operators/developers>

## Dependencies

- Added: <packages or N/A>
- Removed: <packages or N/A>
- Upgraded: <packages and version changes or N/A>
- License/security/size notes: <summary or N/A>
- Why this dependency is needed: <reason>

## Deployment / Operations

- Env vars/config: <changes or N/A>
- Migrations/backfills: <steps or N/A>
- Feature flags: <flags and default state or N/A>
- Rollout order: <steps or N/A>
- Monitoring/alerts/runbook: <links or notes>

## Compatibility

- Browser/platform/device support: <impact or N/A>
- API/backwards compatibility: <impact or N/A>
- Data/schema compatibility: <impact or N/A>
- Version compatibility: <libraries/services/SDKs checked>

## Security / Privacy / Data

- [ ] Auth/authz impact reviewed or not applicable.
- [ ] Secret handling reviewed or not applicable.
- [ ] Data migration, deletion, retention, or PII impact reviewed or not applicable.
- [ ] External network/API behavior reviewed or not applicable.

## Performance / Observability

- [ ] Performance impact reviewed or not applicable.
- [ ] Logging, metrics, tracing, or alert impact reviewed or not applicable.
- [ ] Failure and retry behavior reviewed or not applicable.

## Reviewer Checklist

- [ ] Acceptance criteria are mapped to implementation and evidence.
- [ ] Tests cover the changed behavior or the gap is explained.
- [ ] Typecheck, lint, and build status are known.
- [ ] User-facing behavior and release notes are clear.
- [ ] Rollback path is clear.
- [ ] No unrelated changes, secrets, or user-owned edits are included.

## Reviewer Notes

- <files, edge cases, sequencing, or tradeoffs reviewers should inspect closely>

## Release Notes

<NONE | Internal-only | User-facing note>

## Follow-Ups

- <issue, TODO, owner, or reason deferred>
```

Rules:

- Always include the required core sections.
- Omit optional sections when they are irrelevant; do not fill the PR with noise.
- Use dynamic section selection before drafting; choose sections based on the
  actual touched surfaces, not on PR size.
- Include `Evidence` when `work verify` gathered meaningful external or command evidence.
- Use exact test commands and outcomes; do not write "tested locally" alone.
- React and VS Code emphasize summary/description plus exact testing; use that as
  the baseline reviewer ergonomics when no repo template is present.
- Keep checkbox items in the draft when they help the reviewer see what was verified.
- Include screenshots or videos for UI changes when available.
- Include API examples, migration notes, or release notes for user-facing behavior.
- Include security, data, rollback, or operational risk when the change touches those surfaces.
- Include release notes for user-facing, API, behavior, migration, or operational changes.
- Use `NONE` or `Internal-only` for release notes only when release notes are requested by the repo template.
- Keep hidden template comments out of the final draft body.
- Generate the exact `gh pr create` command for the user to copy/paste: `gh pr create --title "..." --body "..." --draft`. Do not run it automatically unless explicitly asked.
- Automatically include `gh pr edit --add-reviewer <author>` if the issue had a clear author.

## 17. Extract Lessons Learned

Before creating the PR, pause to identify if any new architectural patterns, project-specific rules, or gotchas were established during this issue.
If meaningful new patterns were discovered, use the `memory-merger` or `remember` skill to update the repository's `MEMORY.md` file. Do not record trivial facts or standard language features.
