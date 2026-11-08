#!/bin/bash
# Install or update TodoTim for Omarchy (https://github.com/timvink/todotim), a plugin of the
# Omarchy shell, from its latest linux-v* GitHub release, after verifying the tarball's build
# provenance with `gh attestation verify`. The release's own install.sh copies the plugin to
# ~/.config/omarchy/plugins/timvink.todotim and enables it; tasks in ~/.local/share/todotim are kept.
#
# run_ rather than run_onchange_, like the Mac script: every apply checks for a new release (one
# GitHub API call) and prints nothing when the installed manifest version matches.
# Never installs an unverified build; offline, it keeps the installed version.
# Gated on includePrivate and Omarchy in .chezmoiignore, like ~/.todotim.toml (sync settings).
set -euo pipefail

repo="timvink/todotim"
manifest="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/timvink.todotim/manifest.json"
arch=$(uname -m)
[[ $arch == arm64 ]] && arch=aarch64

warn() { echo "install-todotim: $*" >&2; }

if ! command -v gh >/dev/null || ! gh auth status >/dev/null 2>&1; then
	warn "gh is missing or not logged in (gh auth login), so a release cannot be verified; skipping"
	exit 0
fi

# Mac and Omarchy releases share the repository, so "latest" can be either; take the newest linux-v* tag.
tag=$(gh release list -R "$repo" -L 50 --json tagName -q '[.[].tagName | select(startswith("linux-v"))][0] // empty' 2>/dev/null) || tag=""
if [[ -z $tag ]]; then
	warn "could not look up the latest release (offline?); keeping the installed version"
	exit 0
fi
version=${tag#linux-v}

installed=""
[[ -f $manifest ]] && installed=$(jq -r '.version // empty' "$manifest" 2>/dev/null || true)
[[ $installed == "$version" ]] && exit 0

asset="todotim-omarchy-$version-$arch.tar.gz"
echo "install-todotim: installing TodoTim for Omarchy $version (installed: ${installed:-none})"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir "$tmp/download" "$tmp/unpacked"
gh release download "$tag" -R "$repo" -p "$asset" -D "$tmp/download"

if ! out=$(gh attestation verify "$tmp/download/$asset" --repo "$repo" 2>&1); then
	printf '%s\n' "$out" >&2
	warn "attestation verification FAILED for $asset; not installing"
	exit 1
fi

tar -xzf "$tmp/download/$asset" -C "$tmp/unpacked"
bash "$tmp/unpacked/todotim-omarchy-$version-$arch/install.sh"
