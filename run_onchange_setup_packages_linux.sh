#!/bin/bash
set -euo pipefail

# Tools referenced by dot_bash_aliases.tmpl: eza, bat, nvim, trash-cli (rmtrash alias).
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

# neovim
install_if_missing nvim neovim

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

echo "=== chezmoi: linux CLI tools ready ==="
