#!/bin/bash
set -euo pipefail

# eMudhra intermediate-key compromise, 2026-10-20. Ubuntu's patched bundle
# removes the roots used by the compromised intermediates. Keep this separate
# from general package setup so it can be applied without unrelated installs.
if [ "$(uname -s)" != Linux ]; then
    exit 0
fi
. /etc/os-release
if [ "$ID" = ubuntu ] && [ "$VERSION_ID" = 24.04 ]; then
    sudo apt-get update -qq
    sudo apt-get install -y --only-upgrade ca-certificates
    certificate_version=$(dpkg-query -W -f='${Version}' ca-certificates)
    dpkg --compare-versions "$certificate_version" ge 20260816ubuntu0.24.04.1
fi

# uv has its own bundled Rust roots; updating the OS store alone is insufficient.
# 0.13.5 also publishes managed Python builds with patched pip/ensurepip bundles.
uv_security_version=0.13.5
installed_uv_version=$(uv --version 2>/dev/null | awk '{print $2}' || true)
if [ -z "$installed_uv_version" ] || ! dpkg --compare-versions "$installed_uv_version" ge "$uv_security_version"; then
    curl -fsSL "https://astral.sh/uv/${uv_security_version}/install.sh" \
        | env UV_INSTALL_DIR="$HOME/.local/bin" UV_NO_MODIFY_PATH=1 sh
fi

# This VM also has an older unmanaged binary in /usr/local/bin. Patch explicit
# callers as well as shells whose PATH prefers ~/.local/bin.
if [ -x /usr/local/bin/uv ]; then
    system_uv_version=$(/usr/local/bin/uv --version | awk '{print $2}')
    if ! dpkg --compare-versions "$system_uv_version" ge "$uv_security_version"; then
        sudo install -m 755 "$(command -v uv)" /usr/local/bin/uv
        sudo install -m 755 "$(command -v uvx)" /usr/local/bin/uvx
    fi
fi
