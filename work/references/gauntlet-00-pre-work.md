# Pre-Work Gauntlet

Run before implementation so the AI starts from current facts instead of assumptions.

Before a behavior change, use `superpowers:test-driven-development`. If it is not visible, search for it, report the gap, and follow `references/guide-superpowers.md`.
If the issue describes a bug, crash, or unexpected behavior, invoke the `systematic-debugging` skill BEFORE touching any code to establish a rigorous scientific root-cause hypothesis.

## 1. Repository Orientation

Read the minimal project context:

- `README*`
- package manager lockfile
- `package.json` scripts when present
- framework config files
- test config files
- local agent instructions such as `AGENTS.md`
- `MEMORY.md` to internalize the project's unspoken architectural rules and past lessons

Do not load large generated folders.

## 2. Dependency Inspection

For libraries touched by the issue, inspect the installed package when `node_modules` exists. Prefer primary local files:

- package `package.json`
- exported types
- README
- changelog or migration notes

Then use Context7 or official docs for every external library, SDK, API, CLI, or cloud service touched by the issue. If no external dependency is touched, record that Context7/docs were not applicable.

## 3. Web And GitHub API Research

Always run a bounded public web search for relevant upstream issues, changelogs,
service status, or official announcements connected to the touched external
surface. Prefer official sources and avoid searching private code details.

Always verify current GitHub issue/PR/project state with `gh api` or
`gh api graphql`. Treat memory, notifications, web pages, and prior thread
claims as stale until current GitHub API state agrees.

## 4. Version Drift Check

Compare imported APIs in the codebase with the installed dependency versions. Flag likely drift before coding.

## 5. Security and Safety Check

Look for obvious risks relevant to the issue:

- auth and authorization boundaries
- token or secret handling
- user-controlled input
- file/network access
- data deletion or migration paths

Use native Security for every issue. If the issue clearly has no sensitive surface, record a brief direct security review instead of skipping silently.

## 6. Baseline Commands

Detect available commands from package scripts and repo docs. Prefer the narrowest meaningful baseline:

```bash
pnpm test
pnpm typecheck
pnpm lint
```

Use the repo's actual package manager and scripts. If baseline commands fail before changes, record the failure and avoid mixing it with your later changes.

When a repo needs local environment setup, run the configured repo hook before
commands that require `.env` files. Do not print secret values; report only the
file path and variable names when needed.

## 7. Existing Patterns

Find nearby implementations before designing new abstractions:

```bash
rg "similarFunction|relatedHook|routeName" .
rg --files
```

Prefer existing project patterns over new architecture.

## 8. Duplicate Function Scan

For shared helpers or broad changes, search for existing equivalent logic. Attempt the duplicate-function skill first; if unavailable, report the gap and inspect with `rg`.

## 9. Handoff Checklist

End pre-work with an evidence ledger and checklist:

```text
Evidence ledger:
Superpowers:
GitHub API:
Local dependency artifacts:
Context7 or official docs:
Public web search:
Plugins/skills attempted:
Baseline commands:
Security:
Skipped or not applicable:
```

Keep each line concrete. Include exact `gh api` endpoints or GraphQL operation
names, package files inspected, Context7 library IDs or official-doc URLs, web
URLs, plugin or skill names, command names, and explicit skip reasons.

```text
Explore:
Plan:
Implement:
Verify:
Ship:
Review:
Cleanup:
```

Include the exact commands the AI should run after implementation.
