# Working in this dotfiles repo

Chezmoi-managed dotfiles for one developer. Work directly on `main`; no PR
workflow. Support macOS and Linux (including remote VMs over SSH).

- Prefer `alt` + vim-direction keys for navigation, consistent with tmux and
  VSCode. Keep binding rationale beside its configuration.
- Apps that write their own configuration use `modify_` scripts. Inject managed
  keys while preserving runtime state, such as trust levels and plugin caches.
- Source is authoritative; `chezmoi apply --force` is allowed when an installer
  appended content to a managed file. Prefer applying only affected targets.
- Package scripts: `.chezmoiscripts/run_onchange_setup_packages_darwin.sh` on
  macOS; `run_onchange_setup_packages_linux.sh` on Linux.
- Shared instructions live in `agents/AGENTS.md`; shared skills in
  `agents/skills/`. Edits are live through symlinks or pi's configured skills path.
  Read `agents/README.md` for linking, vendoring, and command-only skills.
- For tmux agent status, read `dot_tmux.conf` and the relevant scripts under
  `dot_local/bin/` (`executable_agent-state*`, `executable_agent-note*`,
  `executable_agent-seen*`, `executable_agent-sleep-guard*`, `executable_tmux-overview*`).
  Lifecycle hooks also live in tool configuration directories.
