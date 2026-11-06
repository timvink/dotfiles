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
- Keyboard (built-in only, keyd): Caps tap = Esc, hold 200 ms = Hyper,
  matching Karabiner on the Mac. No Compose key on the built-in keyboard.
- Netbird mesh VPN (private machines), no Tailscale.
- Agent config: shared AGENTS.md and skills, Claude/Codex/pi settings, MCP
  servers. Omarchy keeps its own skills linked beside mine and updates them.
  Codex uses my ChatGPT subscription; Azure is for the work devbox only.
  Hooks that drive the tmux agent dots wait for the tmux port.
- Git: my ~/.gitconfig over Omarchy's ~/.config/git/config (git reads
  Omarchy's first; mine wins per key). Kept from Omarchy: aliases, histogram
  diffs, rerere, sorting. Mine on top: diff-so-fancy pager, global gitignore,
  log format, gh as GitHub credential helper. Pull rebases and new repos
  start on main, on every machine now. No core.editor: git uses $EDITOR.
- Commit signing: this laptop has its own GPG key (43DDD099D7D191BE), on
  GitHub as "Omarchy laptop (legion-timvink)".
