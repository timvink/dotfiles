# dotfiles

Tim Vink's personal dotfiles managed by [chezmoi.io](https://www.chezmoi.io/).

On a new machine, install `chezmoi` and:

```bash
chezmoi init --apply https://github.com/timvink/dotfiles.git
```

## Setup

My main OS is MacOS, but I try to keep things like keybindings generic as I use linux and windows as well.

Keybindings:

- I have a lot of keybindings setup. Mainly alt + hjkl to navigate consistently in VSCode, Neovim, Firefox and tmux. 
- On my Mac internal keyboard I use [karabiner elements](https://karabiner-elements.pqrs.org/) for key mappings. For example, I've mapped my caps lock key to `ESC` (tapped) and hyper (`shift`+`cmd`+`alt`+`ctrl`) (held more than 250ms).
- I use my ZSA Voyager with custom key mappings (Hyper is a left-thumb hold there, a left-pinky `caps` hold on the Mac — either way Hyper lives on the left hand, so the app launcher below is all left-hand keys).

Hyper + key opens an app (repeat within 1.5s cycles its windows). All keys are
left-hand so the right hand stays free for the mouse. Mnemonics:

| Key | App | Mnemonic |
|-----|-----|----------|
| `A` | Spotify | "Audio" |
| `S` | Teams | "Social" |
| `D` | Ghostty | "Dev" |
| `F` | Firefox | Firefox |
| `W` | Signal ⇄ WhatsApp | "Whisper" / WhatsApp (toggles between the two, Signal first) |
| `E` | Finder | "Explorer" |
| `R` | Obsidian | "Records" |
| `T` | TodoTim | "Todo" |


Apps:

- Terminal: `zsh` on Ghostty with starship.
- Editors: tmux and neovim
- Tiling manager: Rectangle

Azure CLI on Linux has its own Python certificate bundle and pip under `/opt/az`.
The managed `setup_tls_security_linux.sh` updates OS trust and uv;
`setup_azurecli_security_linux.sh` then checks the CLI's certifi and pip on each
apply and patches only those packages when needed. After an Azure CLI package
upgrade, run the targeted check if its bundled versions regress below certifi
2026.10.19 or pip 26.2.2:

```bash
chezmoi apply ~/setup_azurecli_security_linux.sh
```

## Browser sessions on the Mac from the devbox

`host-browser` runs `agent-browser` on the Mac through the existing port **2489**
reverse SSH tunnel. It works with `devbox` and `homelab`, and also runs
directly on the Mac. Each named session has its own visible Chrome window and
persistent profile under `~/.local/share/host-browser/profiles/` on the Mac.
Complete SSO and MFA in that window; later commands reuse the login.
These are separate profiles from your everyday Firefox or Chrome browser.

After syncing this repo, apply the bridge on the Mac:

```bash
chezmoi apply ~/.local/bin/host-browser ~/.local/bin/open-url-listener \
  ~/Library/LaunchAgents/com.timvink.openurl.plist
```

The apply reloads the existing URL listener. `agent-browser` and Chrome for
Testing are already declared in the macOS package setup. If absent, run that
setup before using the bridge. On the devbox, apply the client:

```bash
chezmoi apply --exclude scripts ~/.local/bin/host-browser
```

Use ordinary `agent-browser` commands with the `host-browser` executable:

```bash
host-browser --session work open https://example.com
host-browser --session work snapshot -i
host-browser --session work click @e3
host-browser --session work tab list
host-browser --session work screenshot
host-browser --session work close
host-browser session list
```

Snapshots supply fresh element refs; take another snapshot after a page change.
Closing a session closes that browser and keeps its profile for next time.
`work` is the default session; use different names for independent agents or
accounts. Sessions are named `host-<name>` in the Mac's `agent-browser` list.
Do not use `close --all` when other sessions should keep running.

Piped stdin is forwarded, including `eval --stdin`. Screenshots, PDFs, uploads,
downloads, and other file paths refer to the **Mac's filesystem**. Output and
exit status return to the devbox; files are not copied automatically.
Commands have a 90-second host timeout, a 1 MiB request limit, and an 8 MiB
output limit. Interactive terminal prompts are unsupported; complete sign-in
in the visible Mac browser.

No debugging port or additional SSH forward is needed. The existing URL opener
continues to handle `xdg-open`. Keep the bridge bound to loopback: anyone with
access to it can control the browser and its signed-in accounts.

## MCP sign-in from the headless devbox

Codex's Linux configuration pins `mcp_oauth_callback_port = 43127`. The Mac's
`devbox` SSH connection forwards **Mac `127.0.0.1:43127` → devbox
`127.0.0.1:43127`**. OAuth redirects then reach Codex even though the browser
runs on the Mac. Both ends bind to loopback. macOS Codex keeps its usual temporary
ports, so signing in locally does not claim the devbox tunnel's port.

Apply the relevant sources on each machine:

```bash
# On the devbox:
chezmoi apply ~/.codex/config.toml
# On the Mac, after syncing this repo:
chezmoi apply ~/.local/bin/devbox
```

A newly created `devbox` connection includes the callback forward. An existing
SSH master keeps its old forwards even after the script is updated. To add the
forward to that connection without closing any sessions, run **on the Mac**:

```bash
ssh -S ~/.ssh/cm-devbox.sock -O forward \
  -L 127.0.0.1:43127:127.0.0.1:43127 devbox
```

Then run **on the devbox**, one login at a time:

```bash
codex mcp login atlassian
codex mcp list
```

Complete each provider's sign-in and consent in the Mac browser. The final
callback should load successfully and the CLI should confirm login. Restart an
already running Codex session to load the authenticated tools. Codex owns its
OAuth credential store; tokens do not belong in this repo or `config.toml`.

Linux bash and zsh export `BROWSER="$HOME/.local/bin/xdg-open"`, which sends
the authorization link through the reverse SSH tunnel to the Mac's URL opener.
If an existing shell reports "Browser launch failed", apply `~/.bashrc` on the
devbox and run `export BROWSER="$HOME/.local/bin/xdg-open"` in that shell.
New shells load the setting automatically. Use normal `mcp login` for automatic
opening; `--no-browser` deliberately leaves opening the link to you.

### Fallback when the callback tunnel is unavailable

Both installed clients support a callback paste flow:

```bash
codex mcp login atlassian --no-browser
# For Claude Code's separate credential store:
claude mcp login atlassian --no-browser
```

Run one command, open its printed authorization URL on the Mac, and finish
sign-in. When the browser reaches `http://127.0.0.1:<port>/callback...`, copy
the **full final URL**, including its query string, and paste it directly into
the waiting terminal prompt. A callback page that cannot load is fine: Codex
accepts the URL without fetching it and still validates OAuth state, issuer
and PKCE. Keep callback URLs out of chat, shell commands, logs and commits.
Finish within five minutes for Codex, or rerun the command for a fresh link.

If port 43127 is occupied on either machine, use a temporary listener for that
Codex login instead of stopping the process that owns the port:

```bash
codex mcp login atlassian --no-browser -c mcp_oauth_callback_port=0
```

The existing `xdg-open` rewrite from `localhost` to `devbox` only affects URLs
opened through that helper. It cannot change a later redirect issued by the
OAuth provider. Leave the authorization link's `redirect_uri` unchanged.
The callback paste flow also works without the SOCKS proxy, PAC or URL opener.

Theme: [catppuccin](https://github.com/orgs/catppuccin/repositories?type=all)!
