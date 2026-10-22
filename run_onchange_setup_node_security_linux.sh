#!/bin/bash
set -euo pipefail

# October 2026 Node.js security releases. Patch explicit /usr/bin/node callers
# as well as the personal runtime installed by setup_packages_linux.sh.
[ "$(uname -s)" = Linux ] || exit 0
[ -x /usr/bin/node ] || exit 0

node_is_patched() {
    local version major minimum
    version=$(/usr/bin/node --version | sed 's/^v//')
    major=${version%%.*}
    case "$major" in
        22) minimum=22.23.4 ;;
        24) minimum=24.22.1 ;;
        26) minimum=26.12.1 ;;
        *) return 1 ;;
    esac
    dpkg --compare-versions "$version" ge "$minimum"
}

if ! node_is_patched; then
    sudo apt-get update
    sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y --only-upgrade nodejs
    node_is_patched || { echo 'System Node.js still needs a supported security release' >&2; exit 1; }
fi
