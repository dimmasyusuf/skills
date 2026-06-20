# Personal Multi-Agent Skills

This directory is the source-of-truth for portable personal skills.

Each skill is written to be portable across AI agents. Keep the reusable workflow in
`SKILL.md`, `references/`, `scripts/`, `tests/`, and `assets/`; keep provider-specific
metadata isolated under `agents/`.

## Skills

| Skill | Purpose | Source | Agent metadata |
|---|---|---|---|
| `eod` | End-of-day report workflow that gathers agent session history, GitHub, local git, Gmail, Calendar, memory, and current AI/dev-tooling news | `eod/SKILL.md` | `eod/agents/openai.yaml` |
| `work` | End-to-end GitHub issue workflow: pick issue, create worktree, run setup, verify, prepare commit and PR drafts, and clean up | `work/SKILL.md` | `work/agents/openai.yaml` |

## Installing Locally

Use whichever skill home your current agent runtime reads. The default local
target for these portable skills is `~/.agents/skills`.

```bash
export AGENT_SKILLS_HOME="${AGENT_SKILLS_HOME:-$HOME/.agents/skills}"
mkdir -p "$AGENT_SKILLS_HOME"
ln -sfn "$HOME/Developer/skills/<name>" "$AGENT_SKILLS_HOME/<name>"
```

Install all skills:

```bash
export AGENT_SKILLS_HOME="${AGENT_SKILLS_HOME:-$HOME/.agents/skills}"
mkdir -p "$AGENT_SKILLS_HOME"
for skill in eod work; do
  ln -sfn "$HOME/Developer/skills/$skill" "$AGENT_SKILLS_HOME/$skill"
done
```

## Adding a New Personal Skill

```bash
mkdir -p "$HOME/Developer/skills/<name>"
$EDITOR "$HOME/Developer/skills/<name>/SKILL.md"
ln -sfn "$HOME/Developer/skills/<name>" "${AGENT_SKILLS_HOME:-$HOME/.agents/skills}/<name>"
```

## Conventions

- One directory per skill, named after the skill
- Each skill contains `SKILL.md` with frontmatter (`name`, `description`)
- Provider-specific UI or routing metadata lives under `agents/`
- Scripts should discover their own skill directory or respect `*_SKILL_DIR`
- Tool-specific capabilities are optional adapters; report missing tools and use the closest local fallback
- Personal skills only; team skills should live with the project that owns them
