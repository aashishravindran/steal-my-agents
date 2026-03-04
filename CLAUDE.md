# steal-my-agents

A collection of Claude Code custom agents worth stealing. Each agent is a `.md` file with YAML frontmatter that Claude Code loads from `~/.claude/agents/` (global) or `.claude/agents/` (project-local).

## Structure

- `agents/` — agent `.md` files (one per agent)
- `install.sh` — interactive installer (bash, no external deps)
- `README.md` — public-facing docs

## Conventions

- Commit style: conventional commits (`type(scope): description`)
- Each agent lives in its own file named `<agent-name>.md`
- `install.sh` must stay dependency-free (bash, awk, cp, diff, mkdir only)
- Test the installer manually after changes: `bash install.sh`

## Adding an Agent

1. Drop `agents/<name>.md` with valid YAML frontmatter (`name`, `description`, `model`, `color`)
2. Add a row to the agents table in `README.md`
3. Commit: `feat(agents): add <name> agent`

## Session Log

### 2026-03-03
Created repo with `project-wrapup` agent and interactive `install.sh`. Supports global and local install targets, per-agent selection, and idempotent re-runs.
