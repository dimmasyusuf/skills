# Post-Work Gauntlet

Run `work verify` inside an active worktree after implementation.

Hard rule: do not commit, push, merge, or create a PR unless the user explicitly asks in the current turn. This gauntlet prepares the work for the user.

## 🚨 ZERO-TOLERANCE PRODUCTION SAFETY RULE 🚨

**Zero tolerance for bugs. Zero tolerance for unhandled exceptions. Zero tolerance for regressions.**
Before you consider this issue resolved, you must guarantee that this code will not cause an error in release:
1. **Edge Case Annihilation:** You must actively hunt for null pointers, undefined states, race conditions, database deadlocks, and network timeouts. If a variable *can* be null or undefined, you must explicitly handle it.
2. **Graceful Degradation:** The code must NEVER crash the app. If an external service fails or a database query times out, the feature must degrade gracefully with a safe fallback or a clean error boundary. No silent failures and no white screens of death.
3. **Rigorous Test Enforcement:** If you touched a function, you must verify it has a test covering the happy path AND the catastrophic failure path. 
4. **Prod-Parity Review:** You must review the diff assuming it will be deployed to 1,000,000 concurrent users immediately. Any unhandled promise rejection, memory leak, or missing `try/catch` must result in an instantly blocked PR.

## 1. Changed Files

```bash
git status --short
git diff --stat
git diff --name-only
```

Identify the behavioral surface and the files that need focused review.

## 2. Current GitHub State

Use `gh api` or `gh api graphql` to re-check the issue, linked PRs, review
state, checks, and project state relevant to the branch. Do not rely only on
memory, notifications, or convenience CLI summaries.

## 3. Library Re-Inspection

For changed files that use external libraries, re-check the installed version and relevant API surface. Use local package files first, then Context7 or official docs for every touched library/API.

## 4. Public Web Search

Run a bounded public web search for upstream issues, changelogs, service
status, or official announcements that could affect the touched external
surface. Prefer official sources and do not search private code details.

## 5. New Dependency Inspection

If the diff adds a package, inspect:

- package purpose
- license if relevant
- install footprint
- API used by the change
- security-sensitive behavior

## 6. Tests

Run the narrowest reliable tests first, then broader tests when the change affects shared behavior.

Use the repo package manager:

```bash
pnpm test
pnpm typecheck
pnpm lint
```

Replace with actual scripts from `package.json`.

## 7. Type Check

Run the project's type command when present. For TypeScript repos, do not skip this unless dependencies are unavailable.

## 8. Lint

Run lint or format checks used by the repo. Do not run broad formatting unless the repo expects it.

## 9. Duplicate Function Scan

For helper extraction, cross-module logic, or new utilities, scan for existing equivalent behavior. Attempt the duplicate-function skill first; if unavailable, report the gap and inspect with `rg`.

