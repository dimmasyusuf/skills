# Work Skill Trigger Prompts

Use these as manual routing evals when editing the skill description or `agents/openai.yaml`.

## Should Use Work

- `use the work skill`
- `use the work skill for issue #123`
- `work on example-api #1679`
- `start a worktree for this GitHub issue`
- `work verify`
- `work sync`
- `work resume 2535`
- `work list`
- `work cleanup fix/2535-login-redirect-loop`
- `work standup`

Expected behavior: load `work`, resolve issue/worktree state, and follow the mode-specific workflow.

## Should Prefer Another Skill

- `create a new GitHub issue for this bug` -> use `issue`.
- `write my EOD for today` -> use `eod`.
- `summarize this current session` -> use `session-report`.
- `commit these staged files` -> use `commit-helper`.
- `fix this failing test` with no GitHub issue context -> use `testing-debugging`.
- `split this branch into PRs` -> use `pr-splitter`.
- `rename this thread` -> use `thread-manager`.

Do not use work for one-off commits, pure summaries, issue drafting, or generic debugging when no issue/worktree lifecycle is involved.

## Ambiguous

- `pick up the webhook sync task`
- `continue the frontend bug`
- `what should I work on next`

Expected behavior: use recent context or ask one focused question before starting work.
