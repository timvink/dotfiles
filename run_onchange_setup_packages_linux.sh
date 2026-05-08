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

# starship — official installer drops a binary into /usr/local/bin
if ! command -v starship >/dev/null 2>&1; then
    curl -sS https://starship.rs/install.sh | sudo sh -s -- -y -b /usr/local/bin
fi

# uv — Astral's installer drops a binary into ~/.local/bin
if ! command -v uv >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/uv" ]; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# NOTE on xterm-ghostty terminfo:
# Ghostty is newer than Ubuntu 24.04's ncurses-term package, so the terminfo
# entry isn't available via apt, and ghostty does not ship a .terminfo source
# file in its repo (it's generated from Zig at build time). The canonical fix
# is to run this once from a machine that *has* ghostty installed (e.g. your
# Mac): `infocmp -x xterm-ghostty | ssh <host> tic -x -`. Until then, the
# TERM fallback in dot_bashrc keeps commands like `clear` working.

echo "=== chezmoi: linux CLI tools ready ==="
