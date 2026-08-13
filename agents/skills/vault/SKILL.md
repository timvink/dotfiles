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
**0** in sync, **2** locked, **3** drift, **4** no backup yet. Both 3 and 4 are
resolved the same way — run `update`.

Exit 3 covers two cases, reported by **key name** only (never values):

- `DRIFT` — a key is in the `.env` but missing or different in the vault, i.e.
  the backup is behind.
- `STALE` — a key is still in the vault but has been **deleted** from the
  `.env`. Without this, a removed credential would sit in the backup forever
  while `check` cheerfully reported "in sync".

## Backing up a whole FILE (binary or text) to the vault

A `.env` is a list of separately-editable keys, so `env-vault-sync.sh` diffs it
key by key. Some credentials are not like that: an Android signing keystore, an
SSH or TLS private key, a service-account JSON. Their **bytes** are the secret,
nothing should hand-edit them, and losing the file is unrecoverable in a way
losing a password is not — a lost Play upload key means a key reset with Google,
not a re-issue. Those go in with `file-vault-sync.sh` (next to this file), which
stores the file base64-encoded in the notes of `file-backup:<repo-name>/<path>`,
keyed exactly like the `.env` entries.

```bash
~/.claude/skills/vault/file-vault-sync.sh update  <path/to/file>   # back it up
~/.claude/skills/vault/file-vault-sync.sh check   <path/to/file>   # still current?
~/.claude/skills/vault/file-vault-sync.sh restore <path/to/file>   # machine died
```

- **`update` verifies its own work.** It writes the note, reads it back out of
  the vault, and re-hashes — an unverified backup is not a backup. It refuses
  files over ~7 KB, because a Bitwarden note caps at 10000 characters and a
  silently truncated keystore only fails on the day you need it.
- **`check`** shares the `.env` exit codes: **0** in sync, **2** locked, **3**
  drift, **4** no backup yet. Sync is decided by SHA-256 of the whole file; the
  contents are never printed, only hashes and sizes.
- **`restore`** refuses to overwrite an existing file unless given `--force`,
  restores the original mode, and re-hashes what it wrote against the hash
  recorded in the note.
- A keystore backup is only useful together with its password — keep that in the
  `.env` (already vault-backed) or its own vault entry, and check both are
  current at the same time.

Two rbw quirks this relies on, worth knowing before writing anything else that
drives `rbw add`/`rbw edit`: **rbw silently strips every line starting with `#`**
from the editor buffer, so metadata headers use `;` (also not a base64
character, so a header can never be mistaken for body); and `rbw` has **no
attachment support** (checked through 1.15), which is why the bytes ride in the
notes at all.

## Notes

- The vault server and account are set in the rbw config (chezmoi-managed at
  `~/.config/rbw/config.json`); change settings there, not via `rbw config set`.
  The server may only be reachable on the user's home network or VPN.
- If an entry was just added in the vault's web UI and isn't showing up, run
  `rbw sync` to refresh the local copy.
