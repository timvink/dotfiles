---
name: vault
description: Use rbw to retrieve vault credentials or back up and restore .env and key files. Requires the user to unlock the vault.
---

# Vault access

Use `rbw` against an already-unlocked Bitwarden/Vaultwarden vault. Never run
`rbw login` or `rbw unlock`, and never ask for the master password in chat.
The user authenticates through pinentry on their own terminal.

Check `rbw unlocked` first. If it fails, ask the user to unlock (or log in first
if the device is unregistered), and wait before vault-dependent work. Continue
independent work where possible. A later locked error requires another unlock.

## Read credentials

| Command | Result |
| --- | --- |
| `rbw list` / `rbw search <term>` | Find entry names |
| `rbw get <name>` | Password |
| `rbw get --field <field> <name>` | Named field |
| `rbw get --full <name>` | All entry fields; use only when needed |
| `rbw code <name>` | TOTP code |
| `rbw sync` | Refresh after an entry changed elsewhere |

Pass secrets directly into the consuming command or its environment; avoid
printing them in tool output. For example:

```sh
SOME_TOKEN="$(rbw get 'Some API key')" command-that-needs-token
```

## Back up files

After changing `.env` keys, run `env-vault-sync.sh update <path>`, then `check`.
For created or rotated gitignored key files, use `file-vault-sync.sh update <path>`;
that helper reads back and verifies the backup. These writes are part of the
required backup workflow. Other vault changes need task authorization.

Read [references/backups.md](references/backups.md) before backing up or restoring
files. It covers helper paths, size limits, exit codes, and overwrite protection.
On a locked result, report the pending backup and retry after the user unlocks.
Reading a secret does not require a backup refresh.

## Configuration

The rbw configuration is chezmoi-managed. Change its source template, not the
live `~/.config/rbw/config.json` or `rbw config set`. The vault server may require
the home network or VPN.
