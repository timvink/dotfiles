#!/bin/bash
set -euo pipefail

# Tools referenced by dot_bashrc / dot_bash_aliases.tmpl:
# starship, uv, eza, bat, nvim, trash-cli (rmtrash alias).
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

# NOTE on xterm-ghostty terminfo:
# Ghostty is newer than Ubuntu 24.04's ncurses-term package, so the terminfo
# entry isn't available via apt, and ghostty does not ship a .terminfo source
# file in its repo (it's generated from Zig at build time). The canonical fix
# is to run this once from a machine that *has* ghostty installed (e.g. your
# Mac): `infocmp -x xterm-ghostty | ssh <host> tic -x -`. Until then, the
# TERM fallback in dot_bashrc keeps commands like `clear` working.


# agy — antigravity CLI
if ! command -v agy >/dev/null 2>&1; then
    curl -fsSL https://antigravity.google/cli/install.sh | bash
fi
echo "=== chezmoi: linux CLI tools ready ==="
