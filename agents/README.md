# agents/ — one source of agent config for Claude Code, Codex, Antigravity and pi

This directory is the single source of truth for cross-tool AI-agent config.
Every tool is pointed back at it, so a file here is edited once and live
everywhere — three of them by symlink, pi by config.

```
agents/
├── AGENTS.md     # shared instructions  → ~/.claude/CLAUDE.md  &  ~/.codex/AGENTS.md  &  ~/.gemini/GEMINI.md  &  ~/.pi/agent/AGENTS.md
└── skills/       # shared Agent Skills  → ~/.claude/skills/*  &  ~/.codex/skills/*  &  ~/.gemini/config/skills/*  &  pi's `skills` setting
```

## Why symlinks?

Claude, Codex and Antigravity each read only their own paths and none lets you
add an extra search path in config, so a shared file has to be physically present
in each location:

- **Skills**: Claude scans `~/.claude/skills/`, Codex scans `~/.codex/skills/`
  (its `.system/` is reserved), Antigravity (the `agy` CLI / Gemini) scans
  `~/.gemini/config/skills/` for global skills. Same `SKILL.md` format (folder +
  YAML frontmatter), three dirs.
- **Instructions**: Codex reads `~/.codex/AGENTS.md` natively. Claude reads
  `CLAUDE.md`, **not** AGENTS.md — so `~/.claude/CLAUDE.md` is a symlink to this
  `AGENTS.md` (Claude follows it). Antigravity (the `agy` CLI / Gemini) reads
  `~/.gemini/GEMINI.md`, which is likewise a symlink to this `AGENTS.md`.

Because the symlinks point straight at this repo, editing a file here is instantly
live in every tool — there is no applied copy. `agents/` is `.chezmoiignore`d so
chezmoi never copies it to `~/agents`.

## pi is the exception: it has the config knob

pi takes a `skills` array of arbitrary paths in `~/.pi/agent/settings.json`, so it
reads `agents/skills/` directly and gets no symlink farm. The modify_ script
`private_dot_pi/private_agent/modify_settings.json.tmpl` injects that one entry
and passes through everything pi writes there itself (packages, analytics
opt-ins). It also *seeds* `defaultProvider` and `defaultModel` — written only
when absent, because pi saves the current model back to this file on every
in-session switch (Ctrl+L, Ctrl+P), so force-setting them would drag me back to
the seeded model on the next apply. Change the default by switching models
inside pi, not by editing the script. Instructions still need a link: pi reads
global instructions from `~/.pi/agent/AGENTS.md`, a fixed filename, so that's a
symlink like the rest.

The OpenRouter key those defaults run on is in none of this. The `pi` wrapper in
`dot_bash_aliases.tmpl` reads `openrouter_api_key` from the vault at each launch
and passes it in as `OPENROUTER_API_KEY`, so it exists only in pi's own
environment — never in `~/.pi/agent/auth.json`, which pi rewrites at runtime and
chezmoi therefore can't manage.

`private_` on both source dirs keeps `~/.pi` and `~/.pi/agent` at mode 700, which
is how pi creates them; session transcripts land in `~/.pi/agent/sessions/`.

pi also scans `~/.agents/skills/` on its own. That directory is not chezmoi-managed
— a separate skill installer owns it, tracking what it put there in
`~/.agents/.skill-lock.json` — and pi picks those up without any wiring.

## How the links are created (on `chezmoi apply`)

| Link | Created by |
| ---- | ---------- |
| `~/.claude/CLAUDE.md` → `agents/AGENTS.md` | `dot_claude/symlink_CLAUDE.md.tmpl` |
| `~/.codex/AGENTS.md` → `agents/AGENTS.md` | `dot_codex/symlink_AGENTS.md.tmpl` |
| `~/.gemini/GEMINI.md` → `agents/AGENTS.md` | `dot_gemini/symlink_GEMINI.md.tmpl` |
| `~/.pi/agent/AGENTS.md` → `agents/AGENTS.md` | `private_dot_pi/private_agent/symlink_AGENTS.md.tmpl` |
| `~/.claude/skills/*`, `~/.codex/skills/*`, `~/.gemini/config/skills/*` → `agents/skills/*` | [`.chezmoiscripts/run_onchange_after_link-agents-skills.sh.tmpl`](../.chezmoiscripts/run_onchange_after_link-agents-skills.sh.tmpl) |
| pi's `skills` setting → `agents/skills/` | [`private_dot_pi/private_agent/modify_settings.json.tmpl`](../private_dot_pi/private_agent/modify_settings.json.tmpl) |

## AGENTS.md

Shared, behavioural global instructions for every project. Edit `agents/AGENTS.md`
and `chezmoi apply` (or just edit — the symlinks make it live). Keep it generic;
anything that applies to **all four** tools belongs here.

## skills/

Add `agents/skills/<name>/SKILL.md` (include a `name:` field — Codex and pi both
expect it), then `chezmoi apply`; the link script picks it up. Delete a folder to
remove it (broken symlinks are pruned). pi needs neither step — it reads the
directory live. Store skill scripts with their real names and modes — git tracks
the `+x` bit; do **not** use chezmoi `executable_`/`empty_` prefixes here (this
dir isn't chezmoi-applied, so they wouldn't be stripped). Keep a skill private by
adding its folder name to `skills/.gitignore`; it's still shared with every tool,
just untracked (and would be lost to `git clean -x`, so back it up).

## Tool-specific config (NOT shared)

- **Shared prose rules** (anything Codex must also follow) go in `AGENTS.md`
  above; keep tool-specific rules in the corresponding tool configuration.
- Claude-only or path-scoped rules → `~/.claude/rules/*.md` (`dot_claude/rules/`);
  Claude auto-loads them and supports `paths:` frontmatter for file-scoped rules.
- Codex has **no** prose-rules dir. `~/.codex/rules/` is a command-approval store
  (Starlark `.rules`, like Claude's `settings.json` permissions), not instructions.
- pi appends to or replaces its system prompt from `~/.pi/agent/APPEND_SYSTEM.md`
  and `~/.pi/agent/SYSTEM.md`. Neither is managed — `AGENTS.md` covers the same
  ground for every tool.
- Claude-only skills → `dot_claude/skills/`; Codex-only → `~/.codex/skills/`.

## Command-only skills

`simple-english` is intentionally outside automatic skill discovery. Its files
live in `dot_claude/simple-english/`; `dot_claude/commands/simple-english.md`
loads it when explicitly invoked in Claude. Keep it there for controlled-language
rewrites rather than applying its sentence and vocabulary limits to every reply.

## Vendored skills

A `source:` URL records upstream provenance; `local-edits:` records deliberate
departures to preserve during refreshes. A documentation URL can credit source
material without identifying an upstream skill to copy. Use `update-skill` for
repository-backed updates, and retain licenses when shortening or splitting files.
