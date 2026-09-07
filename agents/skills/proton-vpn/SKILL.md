---
name: proton-vpn
description: Connect, disconnect, or check this machine's Proton WireGuard VPN with the local protonvpn CLI, including downloads blocked by the current exit IP.
---

# Proton VPN

The chezmoi-managed `protonvpn` CLI controls a full tunnel: while connected, all
machine traffic uses the configured Proton server. Check the existing state before
changing it; don't disconnect a tunnel the user already had running for other work.

```sh
protonvpn up       # connect
protonvpn down     # disconnect
protonvpn status   # WireGuard state
protonvpn ip       # public exit IP
```

`up`, `down`, and `status` require sudo. If the current environment cannot satisfy
a sudo prompt, ask the user to run the command in their terminal; never request
the password in chat. Verify the exit IP after connecting or disconnecting.
When a tunnel was opened for this task, close it afterward as requested.

## Configuration and recovery

The private key lives in the vault entry `protonvpn-wireguard`. Non-secret peer
settings live in the chezmoi source
`dot_config/private_wireguard/private_protonvpn.conf.tmpl`; apply renders the key
into the restricted live configuration. Use the `vault` skill for credential work.

Don't use the same WireGuard identity concurrently on multiple machines. For a
server change, obtain the replacement configuration from the user's Proton
account, update the vault key and source template, then apply the affected target.

If Linux reports missing `resolvconf`, address the DNS dependency in the chezmoi
package setup or deliberately adjust the source template. Never patch the rendered
configuration. Persistent `wireguard-tools` installation also belongs in setup.
