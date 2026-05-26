# Working in this dotfiles repo

Chezmoi-managed dotfiles. Single developer, work directly on `main`, no PR
workflow. macOS is primary; everything that lands here should also work on
Linux (used on remote VMs over SSH).

## Design principle: alt+hjkl across all my tools

Navigation uses `alt` + vim-direction keys in cmux (local terminal), tmux
(remote), and VSCode — intentionally identical so muscle memory carries
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
