#!/bin/bash
set -euo pipefail

# Tools referenced by dot_bashrc / dot_bash_aliases.tmpl / dot_gitconfig.tmpl:
# starship, uv, eza, bat, nvim, trash-cli (rmtrash alias), diff-so-fancy, gh.
# Idempotent — chezmoi reruns this only when the file's hash changes.

echo "=== chezmoi: installing linux CLI tools ==="

NEED_UPDATE=0
install_if_missing() {
    local cmd="$1" pkg="$2"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        if [ "$NEED_UPDATE" -eq 0 ]; then
            sudo apt-get update -y
            NEED_UPDATE=1
        fi
        sudo apt-get install -y "$pkg"
    fi
}

# tmux — terminal multiplexer (in the default apt repos)
install_if_missing tmux tmux

# jq — JSON processor. Needed at apply time, not just interactively: the
# modify_ scripts that merge managed keys into ~/.claude/settings.json and
# ~/.pi/agent/settings.json shell out to it, and chezmoi fails the file if it's
# missing.
install_if_missing jq jq

# bat — shipped as 'batcat' on Debian/Ubuntu; symlink to 'bat' in ~/.local/bin
install_if_missing batcat bat
mkdir -p "$HOME/.local/bin"
if [ ! -e "$HOME/.local/bin/bat" ] && command -v batcat >/dev/null 2>&1; then
    ln -s "$(command -v batcat)" "$HOME/.local/bin/bat"
fi

# neovim — apt ships 0.9.x on Ubuntu 24.04 but LazyVim needs >= 0.11.2, so we
# install the upstream prebuilt tarball into ~/.local/opt and symlink to ~/.local/bin.
NVIM_MIN_MAJOR=0
NVIM_MIN_MINOR=11
nvim_ok=0
if command -v nvim >/dev/null 2>&1; then
    ver=$(nvim --version | head -1 | sed -E 's/^NVIM v([0-9]+)\.([0-9]+).*/\1 \2/')
    maj=${ver% *}; min=${ver#* }
    if [ "$maj" -gt "$NVIM_MIN_MAJOR" ] || { [ "$maj" -eq "$NVIM_MIN_MAJOR" ] && [ "$min" -ge "$NVIM_MIN_MINOR" ]; }; then
        nvim_ok=1
    fi
fi
if [ "$nvim_ok" -eq 0 ]; then
    # The symlink in ~/.local/bin will shadow any apt-installed /usr/bin/nvim
    # since ~/.local/bin comes first on PATH.
    mkdir -p "$HOME/.local/opt" "$HOME/.local/bin"
    tmp=$(mktemp -d)
    # Auto-pick the right arch tarball name (nvim-linux-x86_64 since v0.10.4).
    arch=$(uname -m)
    case "$arch" in
        x86_64) nvim_arch=linux-x86_64 ;;
        aarch64) nvim_arch=linux-arm64 ;;
        *) echo "Unsupported arch for nvim prebuilt: $arch" >&2; exit 1 ;;
    esac
    curl -fsSL -o "$tmp/nvim.tar.gz" \
        "https://github.com/neovim/neovim/releases/latest/download/nvim-${nvim_arch}.tar.gz"
    tar -xzf "$tmp/nvim.tar.gz" -C "$tmp"
    rm -rf "$HOME/.local/opt/nvim"
    mv "$tmp/nvim-${nvim_arch}" "$HOME/.local/opt/nvim"
    ln -sf "$HOME/.local/opt/nvim/bin/nvim" "$HOME/.local/bin/nvim"
    rm -rf "$tmp"
fi

# trash-cli — provides 'trash-put'; bash_aliases aliases 'del' to it on linux
install_if_missing trash-put trash-cli

# fzf — fuzzy finder (ctrl-r history, ctrl-t files). Ubuntu's apt fzf is older
# than 0.48, so it lacks `fzf --zsh`; the shell rc falls back to sourcing the
# key-binding files this package drops under /usr/share.
install_if_missing fzf fzf

# xclip — clipboard backend for img-clip.nvim (paste images into markdown).
# X11 only; if a VM ever runs Wayland, swap to wl-clipboard.
install_if_missing xclip xclip

# imagemagick (IM7 `magick`) — snacks.image shells out to the unified `magick`
# binary for in-buffer .png/.jpg previews. Only ImageMagick 7 ships it; Ubuntu
# <= 24.04 / Debian <= bookworm package IM6 (binary `convert`, no `magick`), so
# apt can't deliver it there. Take apt's `magick` only when it's actually IM7,
# else drop ImageMagick's official portable binary into ~/.local/opt and symlink
# it (same vendoring pattern as nvim/diff-so-fancy below; extracted rather than
# run in place so it works headless without FUSE). Inline preview over SSH also
# needs the xterm-ghostty terminfo (run_onchange_setup_ghostty_terminfo.sh) and a
# graphics-capable outer terminal.
if ! command -v magick >/dev/null 2>&1; then
    if [ "$NEED_UPDATE" -eq 0 ]; then
        sudo apt-get update -y
        NEED_UPDATE=1
    fi
    # apt ships IM7 only on Ubuntu 24.10+ / Debian trixie (version epoch 8:7.x);
    # install from apt only there, so older releases fall through to the binary.
    if apt-cache show imagemagick 2>/dev/null | grep -q '^Version: 8:7'; then
        sudo apt-get install -y imagemagick
    fi
fi
if ! command -v magick >/dev/null 2>&1; then
    # Only an x86_64 portable binary is published upstream; other arches fall
    # back to no preview (best-effort on the VMs).
    case "$(uname -m)" in
        x86_64) im_url="https://imagemagick.org/archive/binaries/magick" ;;
        *) im_url=""; echo "imagemagick: no portable binary for $(uname -m); image preview disabled." >&2 ;;
    esac
    if [ -n "$im_url" ]; then
        mkdir -p "$HOME/.local/opt" "$HOME/.local/bin"
        tmp=$(mktemp -d)
        if curl -fsSL -o "$tmp/magick.appimage" "$im_url"; then
            chmod +x "$tmp/magick.appimage"
            # Extract (no FUSE needed) and symlink AppRun, which sets up the
            # bundled libs and dispatches to magick when invoked as `magick`.
            if ( cd "$tmp" && ./magick.appimage --appimage-extract >/dev/null 2>&1 ); then
                rm -rf "$HOME/.local/opt/imagemagick"
                mv "$tmp/squashfs-root" "$HOME/.local/opt/imagemagick"
                ln -sf "$HOME/.local/opt/imagemagick/AppRun" "$HOME/.local/bin/magick"
            else
                echo "imagemagick: AppImage extract failed; image preview disabled." >&2
            fi
        else
            echo "imagemagick: download failed ($im_url); image preview disabled." >&2
        fi
        rm -rf "$tmp"
    fi
fi

# eza — not in default Ubuntu repos; use the official gierens apt repo
if ! command -v eza >/dev/null 2>&1; then
    sudo mkdir -p /etc/apt/keyrings
    if [ ! -f /etc/apt/keyrings/gierens.gpg ]; then
        wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
            | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
        sudo chmod 644 /etc/apt/keyrings/gierens.gpg
    fi
    if [ ! -f /etc/apt/sources.list.d/gierens.list ]; then
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
            | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null
        sudo chmod 644 /etc/apt/sources.list.d/gierens.list
    fi
    sudo apt-get update -y
    sudo apt-get install -y eza
fi

# starship — prefer distro packages. Ubuntu only ships this from 25.04 onward;
# on older releases, install it manually with a reviewed package-manager path
# (e.g. Linuxbrew or cargo) rather than piping the upstream install script to root.
if ! command -v starship >/dev/null 2>&1; then
    if [ "$NEED_UPDATE" -eq 0 ]; then
        sudo apt-get update -y
        NEED_UPDATE=1
    fi
    if apt-cache show starship >/dev/null 2>&1; then
        sudo apt-get install -y starship
    else
        echo "starship is not available in this apt release; install via Linuxbrew or cargo." >&2
    fi
fi

# uv — install the PyPI-published binary into an isolated pipx environment.
if ! command -v uv >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/uv" ]; then
    install_if_missing pipx pipx
    pipx install uv
fi

# fastfetch — neofetch-style system info (config in ~/.config/fastfetch).
# In Ubuntu's universe repo from 24.04 on; older releases lack it, so fall back
# to the upstream prebuilt .deb. Release assets are named by kernel arch
# (amd64 / aarch64), which differs from dpkg's arm64 — map it.
if ! command -v fastfetch >/dev/null 2>&1; then
    if [ "$NEED_UPDATE" -eq 0 ]; then
        sudo apt-get update -y
        NEED_UPDATE=1
    fi
    if apt-cache show fastfetch >/dev/null 2>&1; then
        sudo apt-get install -y fastfetch
    else
        case "$(dpkg --print-architecture)" in
            amd64) ff_arch=amd64 ;;
            arm64) ff_arch=aarch64 ;;
            *) echo "Unsupported arch for fastfetch prebuilt .deb; skipping." >&2; ff_arch="" ;;
        esac
        if [ -n "$ff_arch" ]; then
            tmp=$(mktemp -d)
            curl -fsSL -o "$tmp/fastfetch.deb" \
                "https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-${ff_arch}.deb"
            sudo apt-get install -y "$tmp/fastfetch.deb"
            rm -rf "$tmp"
        fi
    fi
fi

# gh — GitHub CLI, not in default Ubuntu repos; use the official cli.github.com apt repo
if ! command -v gh >/dev/null 2>&1; then
    sudo mkdir -p -m 755 /etc/apt/keyrings
    if [ ! -f /etc/apt/keyrings/githubcli-archive-keyring.gpg ]; then
        wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg \
            | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
        sudo chmod 644 /etc/apt/keyrings/githubcli-archive-keyring.gpg
    fi
    if [ ! -f /etc/apt/sources.list.d/github-cli.list ]; then
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
            | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
        sudo chmod 644 /etc/apt/sources.list.d/github-cli.list
    fi
    sudo apt-get update -y
    sudo apt-get install -y gh
fi

# diff-so-fancy — not in Ubuntu apt; ships as a Perl script + lib from GitHub.
# Install the tagged release tree into ~/.local/opt and symlink the script.
DSF_VERSION=1.4.10
if ! command -v diff-so-fancy >/dev/null 2>&1 \
    || [ "$(diff-so-fancy --version 2>/dev/null | awk '/^Diff-so-fancy/ {print $2; exit}')" != "$DSF_VERSION" ]; then
    mkdir -p "$HOME/.local/opt" "$HOME/.local/bin"
    tmp=$(mktemp -d)
    curl -fsSL -o "$tmp/dsf.tar.gz" \
        "https://github.com/so-fancy/diff-so-fancy/archive/refs/tags/v${DSF_VERSION}.tar.gz"
    tar -xzf "$tmp/dsf.tar.gz" -C "$tmp"
    rm -rf "$HOME/.local/opt/diff-so-fancy"
    mv "$tmp/diff-so-fancy-${DSF_VERSION}" "$HOME/.local/opt/diff-so-fancy"
    ln -sf "$HOME/.local/opt/diff-so-fancy/diff-so-fancy" "$HOME/.local/bin/diff-so-fancy"
    rm -rf "$tmp"
fi

# xterm-ghostty terminfo is installed separately by
# run_onchange_setup_ghostty_terminfo.sh, from a vendored `infocmp -x
# xterm-ghostty`, so snacks.image can detect Ghostty over SSH even on the
# az-ssh'd devbox where Ghostty's own ssh-terminfo integration never runs (it
# only wraps the shell's `ssh`, not `az ssh`). The TERM fallback in dot_bashrc
# covers the gap before that script first applies.


# agy — antigravity CLI
if ! command -v agy >/dev/null 2>&1; then
    curl -fsSL https://antigravity.google/cli/install.sh | bash
fi

# node — needed by pi and agent-browser below. agent-browser wants >= 24, while
# Ubuntu 24.04's apt nodejs is 18.x, so install the upstream prebuilt
# tarball into ~/.local/opt and symlink node/npm/npx into ~/.local/bin (same
# vendoring pattern as nvim / imagemagick / diff-so-fancy above). Follows the
# v24 LTS *line* rather than a pinned patch, so reapplying picks up security
# releases; the version gate below means that only happens on a box whose node
# is missing or too old, never as a surprise upgrade.
NODE_MIN_MAJOR=24
NODE_MIN_MINOR=0
NODE_LTS_DIST=https://nodejs.org/dist/latest-v24.x
node_ok=0
if command -v node >/dev/null 2>&1; then
    ver=$(node --version | sed -E 's/^v([0-9]+)\.([0-9]+).*/\1 \2/')
    maj=${ver% *}; min=${ver#* }
    if [ "$maj" -gt "$NODE_MIN_MAJOR" ] || { [ "$maj" -eq "$NODE_MIN_MAJOR" ] && [ "$min" -ge "$NODE_MIN_MINOR" ]; }; then
        node_ok=1
    fi
fi
if [ "$node_ok" -eq 0 ]; then
    mkdir -p "$HOME/.local/opt" "$HOME/.local/bin"
    arch=$(uname -m)
    case "$arch" in
        x86_64) node_arch=linux-x64 ;;
        aarch64) node_arch=linux-arm64 ;;
        *) echo "Unsupported arch for node prebuilt: $arch" >&2; exit 1 ;;
    esac
    # The release directory listing names the current patch on the LTS line.
    node_tarball=$(curl -fsSL "$NODE_LTS_DIST/" \
        | grep -o "node-v[0-9.]*-${node_arch}\.tar\.gz" | head -1 || true)
    if [ -z "$node_tarball" ]; then
        echo "Could not resolve a Node LTS tarball for $node_arch" >&2
        exit 1
    fi
    tmp=$(mktemp -d)
    curl -fsSL -o "$tmp/node.tar.gz" "$NODE_LTS_DIST/$node_tarball"
    tar -xzf "$tmp/node.tar.gz" -C "$tmp"
    rm -rf "$HOME/.local/opt/node"
    mv "$tmp/${node_tarball%.tar.gz}" "$HOME/.local/opt/node"
    # ~/.local/bin comes first on PATH, so these shadow any apt-installed node.
    for node_bin in node npm npx; do
        ln -sf "$HOME/.local/opt/node/bin/$node_bin" "$HOME/.local/bin/$node_bin"
    done
    rm -rf "$tmp"
fi

# agent-browser — browser automation for coding agents. Install the native CLI
# through npm and keep its Chrome for Testing build ready for headless UI checks.
# The explicit prefix matches the vendored Node layout and avoids writing /usr.
if ! command -v agent-browser >/dev/null 2>&1; then
    export PATH="$HOME/.local/bin:$PATH"
    hash -r 2>/dev/null || true
    npm install --global --prefix "$HOME/.local/opt/node" agent-browser
    ln -sf "$HOME/.local/opt/node/bin/agent-browser" "$HOME/.local/bin/agent-browser"
fi
agent-browser install --with-deps

# pi — agent harness. The upstream installer wraps `npm install -g
# @earendil-works/pi-coding-agent` with a Node version check and prefix
# selection; with no tty it skips its confirmation menu and installs, so it's
# safe from a chezmoi script. It needs the node above already on PATH: its own
# Node-install path is interactive and would bail here. Skills and instructions
# are wired up separately (private_dot_pi/private_agent/); see agents/README.md.
if ! command -v pi >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/pi" ]; then
    (
        export PATH="$HOME/.local/bin:$PATH"
        curl -fsSL https://pi.dev/install.sh | sh
    )
    # With the vendored node, npm's global prefix is ~/.local/opt/node, which
    # isn't on PATH — so pi lands beside it and would be invisible. Link it in
    # next to node/npm/npx. (On a box with a new-enough system node the
    # installer picks the ~/.local prefix itself and this is a no-op.)
    if [ ! -e "$HOME/.local/bin/pi" ] && [ -x "$HOME/.local/opt/node/bin/pi" ]; then
        ln -sf "$HOME/.local/opt/node/bin/pi" "$HOME/.local/bin/pi"
    fi
fi

# pinentry-curses — TTY pass-phrase prompt used by rbw on this headless box.
install_if_missing pinentry-curses pinentry-curses

# rbw — unofficial Bitwarden/Vaultwarden CLI with an ssh-agent-style daemon
# (rbw-agent) that holds the decrypted vault key in memory so scripts don't
# re-prompt. Not packaged in Ubuntu apt, so build it from crates.io. Needs a
# Rust toolchain + a C compiler; install rustup for the user (NOT root) if cargo
# is missing — matches the upstream-installer pattern used above (agy, uv).
# Config lives in ~/.config/rbw/config.json (managed by chezmoi); the encrypted
# vault cache + device registration stay machine-local under ~/.local/share/rbw.
if ! command -v rbw >/dev/null 2>&1; then
    install_if_missing cc build-essential
    install_if_missing pkg-config pkg-config
    if ! command -v cargo >/dev/null 2>&1; then
        [ -f "$HOME/.cargo/env" ] || \
            curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs | sh -s -- -y
        . "$HOME/.cargo/env"
    fi
    cargo install rbw
fi

# bw — the *official* Bitwarden CLI. rbw above is the day-to-day reader (it has
# the agent, so no re-prompting), but it only ever writes to the personal vault:
# it cannot create items owned by an organization. bw can, which is what the
# shared "Vink Family" org needs — bulk import into a collection, org-scoped
# item creation, org exports. Ships as an npm global, so it rides on the
# vendored node above and gets symlinked into ~/.local/bin the same way pi does.
if ! command -v bw >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/bw" ]; then
    (
        export PATH="$HOME/.local/bin:$PATH"
        npm install -g @bitwarden/cli
    )
    if [ ! -e "$HOME/.local/bin/bw" ] && [ -x "$HOME/.local/opt/node/bin/bw" ]; then
        ln -sf "$HOME/.local/opt/node/bin/bw" "$HOME/.local/bin/bw"
    fi
fi

# wireguard-tools — wg/wg-quick for the ProtonVPN tunnel (see the `protonvpn`
# CLI). Linux has in-kernel WireGuard, so no userspace backend is needed. If
# `wg-quick up` later complains about resolvconf for the DNS line, install
# openresolv or drop the `DNS =` line from ~/.config/wireguard/protonvpn.conf.
install_if_missing wg wireguard-tools

# sshfs — lets this box reverse-mount the Mac's ~/Downloads (read-only) at
# ~/mac-downloads automatically while I'm connected (devbox()/homelab() in
# dot_bash_aliases.tmpl bring it up on connect). Only the sshfs client + FUSE are
# needed here (kernel /dev/fuse + fusermount3, both present on the Ubuntu images);
# the Mac side provides dpipe via `vde`.
install_if_missing sshfs sshfs

echo "=== chezmoi: linux CLI tools ready ==="
