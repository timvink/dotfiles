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
- `chezmoi apply --force` is fine when an installer (Antigravity,
  agentsview, …) has appended a line to a managed file; the source is
  authoritative.
- Linux package script: `run_onchange_setup_packages_linux.sh` at repo
  root. macOS: `.chezmoiscripts/run_onchange_setup_packages_darwin.sh`.

## Shared agent config (Claude + Codex)

Cross-tool agent config lives in ONE place at the repo root: `agents/`, holding
`AGENTS.md` (shared global instructions) and `skills/` (shared Agent Skills).
Everything there is symlinked into each tool, since each only scans its own
paths and neither has a config knob for an extra search path:

- `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md` → `agents/AGENTS.md`, via
  `dot_claude/symlink_CLAUDE.md.tmpl` and `dot_codex/symlink_AGENTS.md.tmpl`
  (Claude doesn't read AGENTS.md natively, so its CLAUDE.md is the symlink).
- `~/.claude/skills/*` and `~/.codex/skills/*` → `agents/skills/*`, via
  `run_onchange_after_link-agents-skills.sh.tmpl`.

Symlinks point straight at the repo, so an edit is instantly live in both tools —
no applied copy. `agents/` is `.chezmoiignore`d so chezmoi doesn't also copy it
to `~/agents`. Rules that both tools must follow go in `agents/AGENTS.md` (Codex's
only prose channel); Claude-only/path-scoped rules go in `dot_claude/rules/`. Codex
has no prose-rules dir — its `~/.codex/rules/` is command-approval (Starlark), not
instructions. Full rationale and the add/remove/private-skill workflow are in
`agents/README.md`.
