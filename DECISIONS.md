# Decisions

Choices made while setting up machines. The detailed *why* lives in comments
next to the config.

## Machine kinds

- Detected, not prompted: `mac`, `omarchy`, `server` (any other Linux).
  See `.chezmoitemplates/machine`. `includeDesktop` follows from it.
- Prompted per machine: `includePrivate` (vault, home SSH hosts, Netbird,
  Proton, personal MCP servers) and `codingAgent`.

## Omarchy

Stay as close to stock Omarchy as possible and port my config over one piece
at a time. On Omarchy, `.chezmoiignore` ignores the whole repo except an
allow-list; each ported piece adds its paths there and a line here.

An earlier port (Oct 2026) is kept on the local branch `archive/omarchy-v1`
to cherry-pick from. Its changes to this laptop were reset to stock on
2026-11-06; the files are in `~/omarchy-v1-reset-backup-2026-11-06*.tar.gz`.

Ported:

- Terminal: Ghostty, not Omarchy's default (tabs). Stock Omarchy config.
- Browsers: Chromium (Omarchy's) and Firefox, Firefox as default. By policy:
  Bitwarden (pointed at my Vaultwarden) everywhere, Vimium in Firefox, and
  the browsers' own password managers and autofill off.
  Firefox right-click/context-menu prefs are shared with the Mac through
  `.chezmoitemplates/firefox-user.js` (user.js in each default-release
  profile; policies can't set them). Password manager and autofill are
  already off by policy here, so those prefs are belt-and-suspenders.
- Keyboard (built-in only, keyd): Caps tap = Esc, hold 200 ms = Hyper,
  matching Karabiner on the Mac. No Compose key on the built-in keyboard.
- Netbird mesh VPN (private machines), no Tailscale.
- Agent config: shared AGENTS.md and skills, Claude/Codex/pi settings, MCP
  servers. Omarchy keeps its own skills linked beside mine and updates them.
  Codex uses my ChatGPT subscription; Azure is for the work devbox only.
- Git: my ~/.gitconfig over Omarchy's ~/.config/git/config (git reads
  Omarchy's first; mine wins per key). Kept from Omarchy: aliases, histogram
  diffs, rerere, sorting. Mine on top: diff-so-fancy pager, global gitignore,
  log format, gh as GitHub credential helper. Pull rebases and new repos
  start on main, on every machine now. No core.editor: git uses $EDITOR.
- Shell: bash with Omarchy's stock .bashrc, then my .bash_aliases. Mine win
  for `c` (clear), `t` (my tmux bootstrap), `cat` (bat), git shortcuts and
  the cc/co agent launchers. Omarchy's for `ls`/`lt` (eza; the Mac and
  servers now use the same aliases), `ff` (fzf), `n` and $EDITOR. Sections
  that need unported pieces (pi via rbw) are fenced off in
  dot_bash_aliases.tmpl.
- tmux: my ~/.tmux.conf replaces Omarchy's (prefix stays Ctrl-b). Omarchy's
  tools source ~/.config/tmux/tmux.conf into a running server, so that file is
  a one-line `source-file ~/.tmux.conf`. The socket stays in /tmp (no
  TMUX_TMPDIR) so Omarchy's theme switch and restart scripts find the server.
  With it the agent status machinery: tab dots and notes (Codex hooks, pi
  extensions, the agent-pty shim for Claude, a bash prompt reaper), prefix+o
  overview, alt+f sessionizer, make/just port chip, resurrect/continuum.
  The sleep guard stays Mac-only.
- tmux colours follow the Omarchy theme: dot_tmux.conf reads every colour from
  @thm_* options (Catppuccin Mocha defaults, so the Mac and servers look the
  same), and a theme-set hook writes ~/.config/tmux/theme.conf from the
  theme's colors.toml and re-sources the config. Omarchy's own
  omarchy-theme-set-tmux still sets the pane colours and cursor.
- Vault and SSH (private): rbw built from source with the Vaultwarden
  encryptedFor patch (stock Arch rbw can't write), password prompt as a
  desktop dialog. ~/.ssh/config without the Mac-only homelab forwards.
  Rust via `omarchy install dev-env rust`, on PATH through ~/.bashrc.
- Shell watchdog (temporary): ~/.local/bin/omarchy-shell-watchdog, started
  from autostart.lua, kills the Omarchy shell when it stops answering IPC
  after an NVIDIA resume wedge so Omarchy's launcher relaunches it. Remove
  once omacom/omarchy#10108 is fixed: a post-update hook checks the issue and
  PR #12983 after each `omarchy update` and notifies when either is done.
- Commit signing: this laptop has its own GPG key (43DDD099D7D191BE), on
  GitHub as "Omarchy laptop (legion-timvink)".
- GitHub over SSH: `gh repo clone` and `git clone git@github.com:…` work.
  Reuses the existing ~/.ssh/id_ed25519 (the homelab key) rather than a
  dedicated key — one key, one agent entry, and ~/.ssh/config already points
  github.com at it. The public key is registered on GitHub as an
  authentication key ("GitHub CLI"). Both the registration (GitHub-side) and
  github.com in ~/.ssh/known_hosts (machine-local, not chezmoi-managed, since
  host keys are public) are redone per machine, not reproduced by this repo.
