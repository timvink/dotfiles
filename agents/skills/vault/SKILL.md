---
name: vault
description:
  Retrieve secrets (passwords, API keys, tokens, logins, TOTP codes) from a
  Bitwarden/Vaultwarden vault via the `rbw` CLI. Use whenever a task needs a
  credential the user keeps in their password manager, or when a command or
  script needs a secret value you don't already have.
---

# Vault access (rbw)

The user's passwords live in a Bitwarden/Vaultwarden vault, reached through
[`rbw`](https://github.com/doy/rbw) (an unofficial Bitwarden CLI). A background
`rbw-agent` holds the decrypted vault key in memory after unlock, so once the
user has unlocked you can read secrets repeatedly without any re-prompt.

## Golden rule: you never handle the master password

`rbw login` and `rbw unlock` prompt for the master password through a pinentry
dialog — that is the **user's** job, on their own terminal. **Never run
`rbw login` or `rbw unlock` yourself, and never ask the user to type or paste
the master password into the chat.** You only ever run *read* commands against
an already-unlocked agent.

## Step 1 — check the vault is unlocked

```bash
rbw unlocked        # exit 0 = unlocked; non-zero = locked or not logged in
```

If it exits non-zero, **stop and ask the user to authenticate**, then wait for
them before continuing. Tell them exactly which command to run:

- First time on this machine, or the error is `agent not running` / a login
  error:
  ```bash
  rbw login      # registers the device; asks master password + 2FA
  rbw unlock
  ```
- Otherwise (just locked):
  ```bash
  rbw unlock
  ```

The vault re-locks itself after its `lock_timeout`, so an agent that was
unlocked earlier may need `rbw unlock` again — if a read command fails with a
locked error, ask the user to re-unlock.

## Step 2 — read secrets

```bash
rbw list                        # all entry names
rbw search <term>               # find an entry by name
rbw get <name>                  # the password, on stdout
rbw get --full <name>           # username, password, uri, notes, custom fields
rbw get --field <field> <name>  # one specific field
rbw code <name>                 # current TOTP / 2FA code
```

Consume secrets **inline** rather than printing them — pass the value straight
into the command that needs it:

```bash
export SOME_TOKEN="$(rbw get 'Some API key')"
```

Avoid echoing a secret into output when you can; minimise exposure regardless.

## Backing up `.env` files to the vault

`.env` files are mirrored into the vault so the secrets survive total loss of the
machine (the vault syncs to the user's other devices). The helper
`env-vault-sync.sh` (next to this file) manages it; the whole `.env` is stored in
the notes of an rbw item named `env-backup:<repo-name>/<path-relative-to-repo-root>`
(e.g. `env-backup:timvink-homelab/.env`). Keying on the repo name rather than the
absolute path means the same repo's `.env` maps to the same vault entry on every
machine and checkout (macOS, Linux, a git worktree); outside a git repo it falls
back to `env-backup:<dir-name>/<file>`.

**This is a linter gate: before using any secret from a `.env`, verify the vault
copy is current.**

```bash
~/.claude/skills/vault/env-vault-sync.sh check  <path/to/.env>
~/.claude/skills/vault/env-vault-sync.sh update <path/to/.env>
```

`check` exit codes → what to do:

- **0** — in sync; proceed.
- **3 (drift)** — it prints which **key names** drifted (never values). Tell the
  user, then offer to run `update` (which needs an unlocked vault).
- **2 (locked)** — ask the user to `rbw unlock`, then re-check.
- **4 (no backup yet)** — offer to seed it with `update`.

`update` writes the current `.env` into the vault note via rbw — it needs the
vault unlocked (so the user runs `rbw unlock` first; you never handle the master
password). Run `update` after the user has rotated or added a secret.

## Notes

- The vault server and account are set in the rbw config (chezmoi-managed at
  `~/.config/rbw/config.json`); change settings there, not via `rbw config set`.
  The server may only be reachable on the user's home network or VPN.
- If an entry was just added in the vault's web UI and isn't showing up, run
  `rbw sync` to refresh the local copy.
