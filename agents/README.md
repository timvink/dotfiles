# agents/ — one source of agent config for Claude Code, Codex and Antigravity

This directory is the single source of truth for cross-tool AI-agent config.
Everything here is **symlinked** into the per-tool locations, so it's edited once
and live everywhere.

```
agents/
├── AGENTS.md     # shared instructions  → ~/.claude/CLAUDE.md  &  ~/.codex/AGENTS.md   (not Antigravity — see below)
└── skills/       # shared Agent Skills  → ~/.claude/skills/*  &  ~/.codex/skills/*  &  ~/.gemini/config/skills/*
```

## Why symlinks?

Each tool only reads its own paths and neither lets you add an extra search path
in config, so a shared file has to be physically present in each location:

- **Skills**: Claude scans `~/.claude/skills/`, Codex scans `~/.codex/skills/`
  (its `.system/` is reserved), Antigravity (the `agy` CLI / Gemini) scans
  `~/.gemini/config/skills/` for global skills. Same `SKILL.md` format (folder +
  YAML frontmatter), three dirs.
- **Instructions**: Codex reads `~/.codex/AGENTS.md` natively. Claude reads
  `CLAUDE.md`, **not** AGENTS.md — so `~/.claude/CLAUDE.md` is a symlink to this
  `AGENTS.md` (Claude follows it). Antigravity is **not** wired to `AGENTS.md`:
  it keeps its own (shorter) `~/.gemini/GEMINI.md` (`dot_gemini/GEMINI.md`).
  Only skills are shared with it.

Because the symlinks point straight at this repo, editing a file here is instantly
live in every tool — there is no applied copy. `agents/` is `.chezmoiignore`d so
chezmoi never copies it to `~/agents`.

## How the symlinks are created (on `chezmoi apply`)

| Link | Created by |
| ---- | ---------- |
| `~/.claude/CLAUDE.md` → `agents/AGENTS.md` | `dot_claude/symlink_CLAUDE.md.tmpl` |
| `~/.codex/AGENTS.md` → `agents/AGENTS.md` | `dot_codex/symlink_AGENTS.md.tmpl` |
| `~/.claude/skills/*`, `~/.codex/skills/*`, `~/.gemini/config/skills/*` → `agents/skills/*` | [`.chezmoiscripts/run_onchange_after_link-agents-skills.sh.tmpl`](../.chezmoiscripts/run_onchange_after_link-agents-skills.sh.tmpl) |

## AGENTS.md

Shared, behavioural global instructions for every project. Edit `agents/AGENTS.md`
and `chezmoi apply` (or just edit — the symlinks make it live). Keep it generic;
anything that applies to **both** tools belongs here.

## skills/

Add `agents/skills/<name>/SKILL.md` (include a `name:` field — Codex expects it),
then `chezmoi apply`; the link script picks it up. Delete a folder to remove it
(broken symlinks are pruned). Store skill scripts with their real names and
modes — git tracks the `+x` bit; do **not** use chezmoi `executable_`/`empty_`
prefixes here (this dir isn't chezmoi-applied, so they wouldn't be stripped).
Keep a skill private by adding its folder name to `skills/.gitignore`; it's still
symlinked, just untracked (and would be lost to `git clean -x`, so back it up).

## Tool-specific config (NOT shared)

- **Shared prose rules** (anything Codex must also follow) go in `AGENTS.md`
  above — it's Codex's only prose-instruction channel.
- Claude-only or path-scoped rules → `~/.claude/rules/*.md` (`dot_claude/rules/`);
  Claude auto-loads them and supports `paths:` frontmatter for file-scoped rules.
- Codex has **no** prose-rules dir. `~/.codex/rules/` is a command-approval store
  (Starlark `.rules`, like Claude's `settings.json` permissions), not instructions.
- Claude-only skills → `dot_claude/skills/`; Codex-only → `~/.codex/skills/`.
