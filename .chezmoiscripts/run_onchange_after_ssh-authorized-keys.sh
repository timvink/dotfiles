#!/bin/bash
# Passwordless ssh between my machines (Mac, Legion, homelab), each way.
# Adds each machine's public key to ~/.ssh/authorized_keys when it isn't there
# yet, matched on the key itself so a copy with another comment counts. Only
# adds: other entries stay, such as the phone's Termius key and the homelab's
# command-restricted backup key. Removing a machine means deleting its line
# here and from authorized_keys by hand.
# Public keys only, so fine in a public repo; kept here rather than fetched
# from github.com/<user>.keys so login doesn't depend on GitHub.
# Each sshd is key-only and reachable only from the LAN and NetBird (Omarchy:
# run_onchange_setup_omarchy.sh.tmpl; homelab: timvink-homelab SETUP.md).
set -euo pipefail

keys=$(cat <<'KEYS'
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHRxB+wzYInLUmfwbJlAig2ouZsTH/Gmm4d+1OlAvNIk mac
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII81ocae3kzOgEy7SU3XITUwbe5EH9F7P72BDeYn1BkP legion
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBecfpAvO4Iw+UJmofuiJ40Uq+HACTAaRirJ0ESsym9d homelab
KEYS
)

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
touch "$HOME/.ssh/authorized_keys"
chmod 600 "$HOME/.ssh/authorized_keys"
while read -r type body name; do
    grep -qF "$body" "$HOME/.ssh/authorized_keys" \
        || echo "$type $body $name" >> "$HOME/.ssh/authorized_keys"
done <<< "$keys"
