---
name: proton-vpn
description: >-
  Bring a Proton VPN WireGuard tunnel up or down via the `protonvpn` CLI to get a
  clean exit IP. Use when a download or request is blocked by the machine's home
  IP (e.g. spotdl / yt-dlp hitting "blocked by YouTube Music"), when the user
  asks to route traffic through Proton VPN, or to confirm/teardown the tunnel.
---

# Proton VPN (WireGuard)

A full-tunnel Proton VPN connection over WireGuard, driven by the chezmoi-managed
`protonvpn` CLI (`~/.local/bin/protonvpn`). While it's up, *all* traffic exits
through a Proton free server (currently `NL-FREE#213`).

## Commands

```sh
protonvpn up       # connect (prompts for sudo password — wg-quick needs root)
protonvpn down     # disconnect
protonvpn status   # sudo wg show
protonvpn ip       # print current public IP (verify up/down took effect)
```

`up`/`down`/`status` need **sudo** (the tunnel is a network interface). sudo
prompts for the password on the user's own terminal — you cannot drive it from a
non-interactive shell, so ask the user to run `protonvpn up` themselves.

Typical use — route one job through the VPN, then drop it:

```sh
protonvpn up && make -C ~/workspace/yoto sync ; protonvpn down
```

## How it's stored (and why it travels between machines)

- **Secret:** the WireGuard private key lives in rbw, entry `protonvpn-wireguard`
  (see the [vault] skill — never handle the master password yourself).
- **Non-secret config:** server endpoint, public key, and assigned address live in
  the chezmoi template `dot_config/private_wireguard/private_protonvpn.conf.tmpl`,
  which renders to `~/.config/wireguard/protonvpn.conf` (0600), injecting the key
  from rbw at `chezmoi apply` time.

So a **new machine** (homelab, devbox, …) needs only: rbw unlocked +
`chezmoi apply` (the setup scripts install `wireguard-tools`), then `protonvpn up`.
**No per-machine `.conf` download.**

## Caveats

- **Free tier = one device at a time.** The same key can't be connected from two
  machines simultaneously (WireGuard would flap between endpoints). Use it on one
  machine at a time.
- **Linux DNS:** if `wg-quick up` complains about `resolvconf` for the `DNS =`
  line, install `openresolv` or drop that line from the rendered config.
- **Switching server / country, or if Proton retires the server:** generate one
  new config at account.protonvpn.com → Downloads → WireGuard (pick a `FREE`
  server), then update the single rbw key (`rbw edit protonvpn-wireguard`, or
  remove + re-add) and the `[Peer]` / `Address` fields in the chezmoi template,
  and `chezmoi apply`. It propagates to every machine.
