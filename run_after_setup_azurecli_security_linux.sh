#!/bin/bash
set -euo pipefail

# Azure CLI's private Python bundles certifi and pip independently of the OS.
# An OS CA override cannot remove roots from pip's vendored certifi. Patch only
# these two packages after setup_tls_security_linux has installed secure uv.
[ "$(uname -s)" = Linux ] || exit 0
azurecli_python=/opt/az/bin/python3
[ -x "$azurecli_python" ] || exit 0

uv_binary=$(command -v uv)
uv_version=$("$uv_binary" --version | awk '{print $2}')
if ! dpkg --compare-versions "$uv_version" ge 0.13.5; then
    echo 'Apply setup_tls_security_linux first: Azure CLI patching requires uv >=0.13.5' >&2
    exit 1
fi

security_packages=()
for requirement in certifi:2026.10.19 pip:26.2.2; do
    package=${requirement%%:*}
    minimum_version=${requirement#*:}
    installed_version=$("$azurecli_python" -I -c \
        'import importlib.metadata, sys; print(importlib.metadata.version(sys.argv[1]))' "$package")
    if ! dpkg --compare-versions "$installed_version" ge "$minimum_version"; then
        security_packages+=("$package>=$minimum_version")
    fi
done

if [ "${#security_packages[@]}" -gt 0 ]; then
    # Do not bootstrap through vulnerable pip or upgrade the CLI framework.
    sudo "$uv_binary" --no-config --system-certs pip install \
        --python "$azurecli_python" --system --no-deps "${security_packages[@]}"
fi

for requirement in certifi:2026.10.19 pip:26.2.2; do
    package=${requirement%%:*}
    minimum_version=${requirement#*:}
    installed_version=$("$azurecli_python" -I -c \
        'import importlib.metadata, sys; print(importlib.metadata.version(sys.argv[1]))' "$package")
    dpkg --compare-versions "$installed_version" ge "$minimum_version"
done
