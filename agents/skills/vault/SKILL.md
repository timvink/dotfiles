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

**The trigger is writing, not reading.** After you add, change or remove a key
in a `.env`, refresh the vault copy. Reading a secret out of a `.env` needs no
sync.

```bash
~/.claude/skills/vault/env-vault-sync.sh update <path/to/.env>   # after editing
~/.claude/skills/vault/env-vault-sync.sh check  <path/to/.env>   # is it current?
```

`update` rewrites the vault note from the current `.env`. It needs the vault
unlocked — on exit **2 (locked)**, ask the user to `rbw unlock` and retry; you
never handle the master password yourself.

`check` compares without writing, for when you want to know where things stand:
**0** in sync, **2** locked, **3** drift (it prints the drifted **key names**,
never values), **4** no backup yet. Both 3 and 4 are resolved the same way — run
`update`.

## Notes

- The vault server and account are set in the rbw config (chezmoi-managed at
  `~/.config/rbw/config.json`); change settings there, not via `rbw config set`.
  The server may only be reachable on the user's home network or VPN.
- If an entry was just added in the vault's web UI and isn't showing up, run
  `rbw sync` to refresh the local copy.
