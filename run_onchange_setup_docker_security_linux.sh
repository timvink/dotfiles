#!/bin/bash
set -euo pipefail

# Docker 29.9.2 blocks compromised eMudhra intermediate keys in registry TLS
# verification (CVE-2026-111943). Upgrade an existing Docker installation only.
[ "$(uname -s)" = Linux ] || exit 0
command -v docker >/dev/null 2>&1 || exit 0
. /etc/os-release
[ "$ID" = ubuntu ] || exit 0

docker_security_version=29.9.2
installed_docker_version=$(docker --version | sed -n 's/^Docker version \([^,]*\),.*/\1/p')
if dpkg --compare-versions "$installed_docker_version" ge "$docker_security_version"; then
    exit 0
fi

# Installing docker-ce can restart the daemon. Refuse to interrupt workloads;
# reapply this script once they have been stopped or moved intentionally.
if [ -n "$(docker ps -q)" ]; then
    echo 'Docker security upgrade requires an idle daemon; running containers remain' >&2
    exit 1
fi

docker_packages=()
for package in docker-ce docker-ce-cli docker-ce-rootless-extras containerd.io \
    docker-buildx-plugin docker-compose-plugin docker-model-plugin; do
    if dpkg-query -W -f='${db:Status-Status}' "$package" 2>/dev/null | grep -qx installed; then
        docker_packages+=("$package")
    fi
done
if [ "${#docker_packages[@]}" -eq 0 ]; then
    echo 'Installed Docker is not managed by the expected APT packages' >&2
    exit 1
fi
sudo apt-get update -qq
sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y --only-upgrade "${docker_packages[@]}"
installed_docker_version=$(docker --version | sed -n 's/^Docker version \([^,]*\),.*/\1/p')
dpkg --compare-versions "$installed_docker_version" ge "$docker_security_version"
