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
- Browsers: Chromium (Omarchy's) and Firefox, Firefox as default.
- Keyboard (built-in only, keyd): Caps tap = Esc, hold 200 ms = Hyper,
  matching Karabiner on the Mac. No Compose key on the built-in keyboard.
- Netbird mesh VPN (private machines), no Tailscale.
