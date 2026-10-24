#!/bin/sh
# Install or update TodoTim (https://github.com/timvink/todotim) in /Applications from its latest GitHub
# release, after verifying the zip's build provenance with `gh attestation verify`.
#
# run_ rather than run_onchange_: a run_onchange_ script reruns only when its own content changes, so it
# would never notice a new release. As a run_ script, every `chezmoi apply` checks for one, at the cost of a
# single GitHub API call; when the installed CFBundleShortVersionString matches the latest tag it prints
# nothing. run_after_ so that gh and jq from run_onchange_setup_packages_darwin.sh exist on a fresh machine.
#
# Never installs an unverified build: without gh it skips the update, and a failed attestation stops the
# script with an error. Offline, it warns and leaves the installed app alone.
#
# The zip is fetched with curl, which sets no quarantine attribute, so the ad-hoc signed app opens without
# Gatekeeper's Open Anyway step. The attestation check is what ties it to the repository instead.
#
# Gated on includePrivate and darwin in .chezmoiignore, like ~/.todotim.toml.
set -eu

repo="timvink/todotim"
app="/Applications/TodoTim.app"
bundle_id="nl.timvink.todotim"

warn() { echo "install-todotim: $*" >&2; }

gh_ready=0
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then gh_ready=1; fi

# Latest release tag and zip URL. gh when it is logged in, the public API otherwise.
if [ "$gh_ready" -eq 1 ]; then
	release=$(gh release view -R "$repo" --json tagName,assets 2>/dev/null) || release=""
else
	release=$(curl -fsSL --max-time 20 -H "Accept: application/vnd.github+json" \
		"https://api.github.com/repos/$repo/releases/latest" 2>/dev/null) || release=""
fi
if [ -z "$release" ]; then
	warn "could not look up the latest release (offline?); keeping the installed version"
	exit 0
fi
# gh calls the fields tagName and url (the download URL); the REST API tag_name and browser_download_url.
tag=$(printf '%s' "$release" | jq -r '.tagName // .tag_name // empty')
asset="TodoTim-$tag.zip"
url=$(printf '%s' "$release" | jq -r --arg name "$asset" \
	'first(.assets[] | select(.name == $name) | .browser_download_url // .url) // empty')
if [ -z "$tag" ] || [ -z "$url" ]; then
	warn "latest release has no $asset asset; keeping the installed version"
	exit 0
fi
version=${tag#v}

installed=""
if [ -f "$app/Contents/Info.plist" ]; then
	installed=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$app/Contents/Info.plist" 2>/dev/null || true)
fi
[ "$installed" = "$version" ] && exit 0

if [ "$gh_ready" -eq 0 ]; then
	warn "TodoTim $tag is available, but gh is missing or not logged in (gh auth login), so it cannot be verified; not installing"
	exit 0
fi

echo "install-todotim: installing TodoTim $tag (installed: ${installed:-none})"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir "$tmp/download" "$tmp/unpacked"
curl -fsSL --max-time 300 -o "$tmp/download/$asset" "$url"

if ! out=$(gh attestation verify "$tmp/download/$asset" --repo "$repo" 2>&1); then
	printf '%s\n' "$out" >&2
	warn "attestation verification FAILED for $asset; not installing"
	exit 1
fi

ditto -x -k "$tmp/download/$asset" "$tmp/unpacked"
new_app="$tmp/unpacked/TodoTim.app"
new_id=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$new_app/Contents/Info.plist" 2>/dev/null || true)
if [ "$new_id" != "$bundle_id" ]; then
	warn "$asset does not contain the expected TodoTim.app; not installing"
	exit 1
fi

# Quit the app normally so it flushes pending saves; never kill it.
was_running=0
if pgrep -x TodoTim >/dev/null 2>&1; then
	was_running=1
	osascript -e "quit app id \"$bundle_id\"" >/dev/null 2>&1 || true
	i=0
	while pgrep -x TodoTim >/dev/null 2>&1; do
		i=$((i + 1))
		if [ "$i" -gt 30 ]; then
			warn "TodoTim did not quit within 15 seconds; quit it and run chezmoi apply again"
			exit 1
		fi
		sleep 0.5
	done
fi

# Stage next to the target, then swap, so a failed copy never leaves a half-written app behind.
staged="/Applications/.TodoTim.app.installing"
rm -rf "$staged"
ditto "$new_app" "$staged"
rm -rf "$app"
mv "$staged" "$app"
echo "install-todotim: installed TodoTim $tag"

if [ "$was_running" -eq 1 ]; then
	open "$app"
fi
