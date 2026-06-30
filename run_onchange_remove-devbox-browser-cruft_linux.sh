#!/bin/bash
set -euo pipefail

# Remove devbox VM-provisioning cruft that shadows our URL-opening shim.
#
# A fresh devbox image drops a rogue print-only /usr/local/bin/xdg-open (owned
# by no package) and an /etc/profile.d/devbox-browser.sh that exports
# $BROWSER=/usr/local/bin/xdg-open. Both shadow the real ~/.local/bin/xdg-open
# shim, which forwards URLs to the Mac's open-url-listener over the SSH reverse
# tunnel (see dot_local/bin/executable_xdg-open). Our zshrc re-exports $BROWSER
# back to the good shim, so interactive shells are fine — but non-interactive
# ones (and anything reading $BROWSER outside an interactive login) get the dud.
# prefix+u dodges it (PATH -> ~/.local/bin first), but make-serve/az-login URLs
# wouldn't reach the Mac. Clear it so the shim is the only xdg-open on the box.
#
# Idempotent: only escalates when a file is actually present, so it's a silent
# no-op (no sudo) on clean machines. Hash-tracked — chezmoi reruns this only
# when the file's contents change, plus on a fresh checkout (e.g. a rebuilt
# devbox), which is exactly when the cruft is back.

removed=0
for f in /etc/profile.d/devbox-browser.sh /usr/local/bin/xdg-open; do
    if [ -e "$f" ]; then
        sudo rm -f "$f"
        removed=1
    fi
done

if [ "$removed" -eq 1 ]; then
    echo "=== chezmoi: removed devbox-browser provisioning cruft ==="
fi
