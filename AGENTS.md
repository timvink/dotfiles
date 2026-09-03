# Working in this dotfiles repo

Chezmoi-managed dotfiles. Single developer, work directly on `main`, no PR
workflow. macOS is primary; everything that lands here should also work on
Linux (used on remote VMs over SSH).

## Design principle: alt+hjkl across all my tools

Navigation uses `alt` + vim-direction keys in tmux (terminal, local and
remote) and VSCode — intentionally identical so muscle memory carries
between them. When adding a new binding anywhere, prefer `alt+<vim-key>` if
it fits the cross-tool model. Specific bindings and their rationale are
documented next to the configs that set them.

## chezmoi conventions

- **Apps that mutate their own config at runtime** (Claude Code's
  `settings.json`, Codex's `config.toml`, etc.) use `modify_` chezmoi
  scripts that inject only our managed keys/lines and preserve runtime
  state (project trust levels, plugins, marketplace caches). Don't fully
  manage these files — `chezmoi apply` would clobber runtime additions.
- `chezmoi apply --force` is fine when an installer (Antigravity, …)
  has appended a line to a managed file; the source is authoritative.
- Linux package script: `run_onchange_setup_packages_linux.sh` at repo
  root. macOS: `.chezmoiscripts/run_onchange_setup_packages_darwin.sh`.

## Shared agent config (Claude + Codex + Antigravity + pi)

Cross-tool agent config lives in ONE place at the repo root: `agents/`, holding
`AGENTS.md` (shared global instructions) and `skills/` (shared Agent Skills).
Claude, Codex and Antigravity each scan only their own paths and none has a
config knob for an extra search path, so everything is symlinked into each tool:

- `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md` and `~/.gemini/GEMINI.md`
  (Antigravity / agy) → `agents/AGENTS.md`, via `dot_claude/symlink_CLAUDE.md.tmpl`,
  `dot_codex/symlink_AGENTS.md.tmpl` and `dot_gemini/symlink_GEMINI.md.tmpl`
  (Claude doesn't read AGENTS.md natively, so its CLAUDE.md is the symlink; same
  for Gemini's GEMINI.md). One instruction file, all three tools.
- `~/.claude/skills/*`, `~/.codex/skills/*` and `~/.gemini/config/skills/*`
  (Antigravity's global skills dir) → `agents/skills/*`, via
  `run_onchange_after_link-agents-skills.sh.tmpl`.

pi is the exception, wired up in `private_dot_pi/private_agent/`: it takes a
skills path list in its `settings.json`, so it reads `agents/skills/` directly
instead of getting a symlink farm. See `agents/README.md`.

Symlinks point straight at the repo, so an edit is instantly live in every tool —
no applied copy. `agents/` is `.chezmoiignore`d so chezmoi doesn't also copy it
to `~/agents`. Rules that every tool must follow go in `agents/AGENTS.md` (Codex's
only prose channel); Claude-only/path-scoped rules go in `dot_claude/rules/`. Codex
has no prose-rules dir — its `~/.codex/rules/` is command-approval (Starlark), not
instructions. Full rationale and the add/remove/private-skill workflow are in
`agents/README.md`.

## Command-only skills (Claude)

A skill I want to reach for by hand, never loaded automatically, is vendored
outside every tool's skills path and driven by a slash command. `simple-english`
is the pattern: the skill files live in `dot_claude/simple-english/` (nothing
scans that directory) and `dot_claude/commands/simple-english.md` tells Claude to
read `~/.claude/simple-english/SKILL.md`. Claude-only, because Codex has no
slash-command mechanism to point at it. Vendored copies keep a `source:` line in
their frontmatter so the `update-skill` skill can re-sync them.

Implementation details for the per-tab tmux agent-state dot, note, subagent
count, prefix+o overview, and lid-close sleep guard live in the
`tmux-agent-status` skill — load it when working on `dot_tmux.conf`, the
`agent-state`/`agent-note`/`agent-seen`/`agent-state-sweep`/`agent-sleep-guard`
scripts, or `tmux-overview`.

