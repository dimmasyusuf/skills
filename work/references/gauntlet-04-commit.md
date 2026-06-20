## 15. Draft Commit Message

Prepare, but do not run, a conventional commit message:

```text
<type>(<scope>): <subject>

<body: why this changed, behavior impact, and verification summary>

Closes #<issue-id>
```

Rules:

- Type comes from branch prefix when possible.
- Scope comes from the most-touched directory.
- Subject is imperative, lowercase, and has no trailing period.
- Body explains motivation and behavior impact, not just a file list.
- Body may compare previous behavior with new behavior when that clarifies risk.
- Include a compact verification paragraph or bullet list with exact commands.
- Use `BREAKING CHANGE:` or `DEPRECATED:` footers only when applicable and include migration guidance.
- Use `Closes #<issue-id>`, `Fixes #<issue-id>`, or `Refs #<issue-id>` intentionally.
- Lines are at most 100 characters.
- No co-author footer.
- No emoji.

Prefer the practical intersection of Conventional Commits and large
open-source repo practice:

- Angular-style header/body/footer discipline.
- Node-style scoped prefix where a package/subsystem is clearer than a directory.
- React/Next-style explanatory body for complex behavior.
- Keep generated review metadata out of the commit unless the repo requires it.

