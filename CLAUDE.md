# Working in this dotfiles repo

Chezmoi-managed dotfiles. Single developer, work directly on `main`, no PR
workflow.

## Muscle memory: alt+hjkl across all my tools

I intentionally use the same `alt` + vim-direction keys for navigation in
cmux (local terminal), tmux (remote VMs over SSH), and VSCode. The
mappings line up so the muscle memory carries between all three:

| Keys                | Action                       |
|---------------------|------------------------------|
| `alt+h` / `alt+l`   | previous / next tab          |
| `alt+j` / `alt+k`   | next / previous workspace    |
| `alt+t` / `alt+n`   | new tab / new workspace      |
| `alt+r` / `alt+R`   | rename tab / rename workspace|

In tmux: **session = workspace**, **window = tab**, pane = a split inside
a tab (rarely used; `prefix h/j/k/l` for splits). Bindings live in
`dot_tmux.conf` as prefix-less `M-…` so they work in any pane without a
prefix dance. Use `Ctrl-b r` to reload `~/.tmux.conf` after changes.

## Two non-obvious requirements

- **Ghostty needs `macos-option-as-alt = left`** (in
  `dot_config/ghostty/config`) so left-Option reaches tmux as Meta over
  SSH. Right Option still types special chars (`#`, accents). Ghostty's
  own tab nav is on `super+shift+j/k` (Cmd-based), so it never collides
  with tmux's Alt bindings.

- **`t` alias** (`tmux new -A -s main`, in `dot_bash_aliases.tmpl`) is
  how I start tmux. Plain `tmux` silently creates a new session each
  time and orphans the previous one — defeats the persistence point.

## Per-tab agent state dots in tmux

The tmux status bar shows a coloured dot per tab to convey agent state:

| Dot       | Meaning                                            |
|-----------|----------------------------------------------------|
| green ●   | producing output / running                         |
| yellow ●  | agent needs attention (permission prompt)          |
| grey ○    | turn complete, awaiting next prompt                |

State is set explicitly by agent lifecycle hooks calling
`~/.local/bin/agent-state <state>` (source:
`dot_local/bin/executable_agent-state`). Wired up for:

- **Claude Code** (`dot_claude/modify_settings.json`):
  `UserPromptSubmit`/`PreToolUse` clear state · `Stop` → `idle` ·
  `Notification` → `needs-input`.
- **Codex** (`dot_codex/modify_private_config.toml`): single `notify`
  event → `idle`.

Non-agent tabs fall through to tmux's `monitor-activity` /
`monitor-silence` / `monitor-bell` flags. The explicit-state design
exists because TUIs (Claude Code, Codex, vim, top) constantly repaint,
which breaks naive `monitor-silence` detection.

## chezmoi conventions

- Apps that mutate their own config at runtime (Claude Code's
  `settings.json`, Codex's `config.toml`) use **`modify_` chezmoi
  scripts** that inject only our managed keys/lines and preserve
  runtime state (project trust levels, installed plugins, marketplace
  caches, etc.).
- `chezmoi apply --force` is fine when an installer (Antigravity,
  agentsview, …) has appended a line to a managed file; the source is
  authoritative.
- Linux package script is `run_onchange_setup_packages_linux.sh` at
  repo root; macOS is `.chezmoiscripts/run_onchange_setup_packages_darwin.sh`.
