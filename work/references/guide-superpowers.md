# Native Superpowers

Always use the native Superpowers skill for the matching stage. If a
required skill is not immediately visible, search for it with `tool_search`.
Only continue without it after reporting the gap and applying the equivalent
local checks below.

## Required Checks

Attempt these skills at the matching stage:

| Work stage | Superpowers skill |
|---|---|
| Worktree setup | `superpowers:using-git-worktrees` |
| Behavior change | `superpowers:test-driven-development` |
| Debugging | `superpowers:systematic-debugging` |
| Larger plan | `superpowers:writing-plans` |
| Plan execution | `superpowers:executing-plans` |
| Code review request | `superpowers:requesting-code-review` |
| Review feedback | `superpowers:receiving-code-review` |
| Cleanup | `superpowers:finishing-a-development-branch` |
| Completion claim | `superpowers:verification-before-completion` |
| Editing this skill | `superpowers:writing-skills` |

## Missing Skill Behavior

If a required Superpowers skill is not visible:

1. Search for it with `tool_search`.
2. If still unavailable, inspect plugin install candidates for a native Superpowers plugin.
3. Install/request only an exact native Superpowers plugin match.
4. If no native candidate exists, report the gap and continue with equivalent local checks.

Do not install or port provider-specific Superpowers copies into this skill.
