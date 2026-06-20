## 10. Senior Engineer Quality Gate

Review the changed code like the senior engineer for the surface being touched.
This is a blocking quality gate, not a style pass.

### Uncompromising Utility Reuse & No-Duplication Rule

**Before writing a single line of new logic** for a helper, hook, service, abstraction, query wrapper, formatter, or component API, you MUST ruthlessly search the codebase for existing equivalents:

```bash
rg --files | rg '(^|/)(utils?|helpers?|lib|shared|common|hooks|services|components|modules|packages)(/|$)'
rg "<domain term>|<new helper name>|<similar behavior>" .
```

- **Zero-Tolerance for Duplication:** If an existing utility, component, hook, service, mapper, validator, or test helper can be reused (even if it requires a minor, safe refactor), **use it**. Do not create a new file or local copy.
- **Forced Justification:** If you decide to create a completely new abstraction, you must record an explicit, rigorous justification in your evidence ledger explaining exactly why the 5 closest existing utilities in the codebase could not be adapted. The Senior Architecture Subagent will aggressively reject the PR if this is missing.

### Architectural Integrity

- Invoke the `improve-codebase-architecture` skill to review the diff for structural regressions, spaghetti code, and boundary violations.

### Simplification Pass

Attempt simplification tooling before final approval:

- Use `code-modernization` for scoped simplification, duplication removal, type
  safety cleanup, and behavior-preserving maintainability work.
- Search for `code-simplifier` or `code-simplify` with `tool_search`; if a native
  skill/plugin is visible, use it. If it is unavailable, report that gap
  and perform the direct simplification review below.
- Attempt CodeRabbit or another code-review plugin after local simplification so
  external review sees the cleanest diff.

Direct simplification review:

- remove needless wrappers, state, flags, branches, and one-off abstractions
- keep behavior changes separate from cleanup
- prefer existing project APIs over new local copies
- keep public contracts stable unless the issue requires a contract change
- verify no error handling, authorization, observability, or data integrity path
  was simplified away

### Role Lens

Use the relevant senior-engineer lens and record it in the evidence ledger:

- backend lens: API contracts, authz/authn, validation, transaction boundaries,
  idempotency, retries, queues, migrations, indexes, data integrity, logging,
  observability, performance, and failure modes.
- frontend lens: rendered behavior, accessibility, responsive layout, loading and
  empty states, error states, data fetching/cache correctness, component reuse,
  state ownership, browser console health, and visual regression risk.
- mobile lens: navigation lifecycle, permissions, offline/poor-network behavior,
  platform differences, native module boundaries, app state changes, and device
  verification.
- database/API lens: schema compatibility, backfills, indexes, N+1 queries,
  pagination, rate limits, versioned contracts, and rollback safety.
- infrastructure/integration lens: secrets, environment drift, retries,
  timeouts, webhooks, third-party API limits, observability, and safe rollout.

Block completion when the code is correct but not senior-quality: duplicated
helpers, avoidable complexity, unverified utility reuse, vague ownership,
missing failure handling, or untested domain-specific risks must be fixed or
explicitly reported as unresolved.

## 11. Code Review (Dynamic Multi-Agent Delegation)

Use the `invoke_subagent` tool to delegate code review. Launch a dynamic fleet of specialized subagents concurrently to cover all angles of your diff. Do not limit yourself to just one or two. Leverage the `workflow-orchestration-patterns` skill to effectively manage this multi-agent execution. 

Example roles and criteria to launch based on what files changed:
- **Security Reviewer Subagent:** (Always run) Review for vulnerabilities, secrets, injection risks, and auth bypasses.
- **Senior Architecture & Structure Subagent:** (Always run) Review for separation of concerns, design patterns, DRY/KISS principles, and clean dependency management.
- **API Contract & Compatibility Subagent:** If APIs/SDKs changed, review for backwards compatibility, versioning, and contract stability.
- **UI/UX & Accessibility Subagent:** If frontend/mobile files changed, review for contrast, screen-reader semantics (a11y), and responsive edge-cases.
- **Performance & Scalability Subagent:** If loops, data processing, or heavy computations changed, review for O(N) complexity, memory leaks, and render bottlenecks.
- **Database & Data Integrity Subagent:** If schemas, ORMs, or SQL changed, review for N+1 queries, indexing, migrations, and rollback safety.
- **Observability & Reliability Subagent:** Review error boundaries, logging clarity, retry mechanisms, and failure state handling.
- **Domain/Business Logic Subagent:** Ensure the code actually maps to the issue's business requirements and handles domain-specific edge cases.
- **Code Modernization Subagent:** Look for places to use more modern, simplified language features rather than verbose legacy patterns.
- **Testing Strategist Subagent:** Analyze the diff specifically for edge cases, race conditions, and error paths missing from the test coverage.

Launch as many relevant subagents as possible at once. Wait for their reports. Findings should lead with severity, file, and line. Block completion on critical or high-confidence behavioral bugs.

