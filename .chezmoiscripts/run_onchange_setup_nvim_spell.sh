#!/bin/sh
# Download the Dutch spell dictionary for Neovim so prose spell-checking
# (spelllang=en,nl, set in dot_config/nvim/lua/config/options.lua) recognises
# Dutch on every machine. Neovim ships only the English dictionary; without
# this, opening markdown triggers a one-time download prompt that's easy to miss.
#
# Cross-platform: identical curl + path on macOS and Linux, so no OS suffix.
# Idempotent — only fetches files that are missing. chezmoi reruns this only
# when its hash changes.
#   nl.utf-8.spl = dictionary, nl.utf-8.sug = better `z=` suggestions.

set -eu

spell_dir="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/spell"
base_url="https://ftp.nluug.nl/pub/vim/runtime/spell"

mkdir -p "$spell_dir"

for f in nl.utf-8.spl nl.utf-8.sug; do
    [ -f "$spell_dir/$f" ] && continue
    echo "nvim spell: downloading $f"
    if ! curl -fsSL -o "$spell_dir/$f" "$base_url/$f"; then
        echo "nvim spell: failed to download $f (offline?), skipping" >&2
        rm -f "$spell_dir/$f"
    fi
done
