#!/usr/bin/env bash
# native Superpowers composition helpers.

work_superpower_required_skills() {
  cat <<'EOF'
superpowers:using-git-worktrees
superpowers:test-driven-development
superpowers:systematic-debugging
superpowers:verification-before-completion
superpowers:writing-plans
superpowers:executing-plans
superpowers:requesting-code-review
superpowers:receiving-code-review
superpowers:finishing-a-development-branch
superpowers:writing-skills
EOF
}

work_superpower_preflight_message() {
  cat <<'EOF'
Use native Superpowers skills at the matching stage:
- before worktree operations: superpowers:using-git-worktrees
- before behavior changes: superpowers:test-driven-development
- when debugging: superpowers:systematic-debugging
- before completion claims: superpowers:verification-before-completion
- when editing this skill: superpowers:writing-skills

If a Superpowers skill is not visible, search with tool_search. If no native Superpowers plugin is available, report that gap and continue with equivalent local checks rather than using provider-specific ports.
EOF
}
