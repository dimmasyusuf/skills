# Project Configuration

This skill is intentionally project-neutral. Keep private organization names,
repository names, internal services, and personal paths out of this repository.
Put local-only configuration in `~/.config/work/config` or another ignored file
that is not committed.

## Workspace

- Source repos can live anywhere under a common workspace root.
- Worktrees live under `$WORKSPACE_ROOT/.worktrees/<repo>/<issue>-<slug>`.
- Multiple active worktrees can exist at once across different repositories.

## Env Setup

This public skill does not include built-in company-specific environment hooks.
Define repo-specific hooks in your local config when needed:

```bash
work_env_setup__example_app() {
  cp .env.example .env.local
  work_set_env_value .env.local APP_URL http://localhost:3000
}

work_safety_check__example_app() {
  test -f package.json
}
```

Rules:

- Prefer reproducible setup from `.env.example`, local secret managers, or
  documented project commands.
- Do not print secret values.
- Do not commit `.env`, `.env.local`, tokens, credentials, or private endpoint
  values.
- Keep private CLI names and internal service URLs in local config only.

## Optional Tunnel Helper

`work_env_patch_tunnel` can patch common frontend/backend URL variables for
public tunnel services. Configure path and ports with environment variables:

```bash
WORK_TUNNEL_FRONTEND_PORT=3000
WORK_TUNNEL_BACKEND_PORT=8080
WORK_TUNNEL_API_PATH=/api
work_env_patch_tunnel .env.local .env https://abc123-3000.example.dev/
```

## Project Board

Project writes are off unless `WORK_PROJECT_WRITE=1`. If the user only has read
access, `work_project_move_in_progress` should return `skipped`, `not-found`,
`list-error`, or `edit-error` and continue.

Do not call `gh project item-add` from this skill. Missing project items are reported, not created.

## Local Checks

Read repo instructions before broad commands. Prefer narrow local checks when a
repo documents restrictions around broad lint, test, or typecheck runs.
