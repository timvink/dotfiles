# .env files are vault-backed

Secrets in a `.env` are mirrored into my password vault. Before reading or
using any secret from a `.env` (or `.env.local`, etc.), gate on the backup being
current — run the `vault` skill's helper:
`~/.claude/skills/vault/env-vault-sync.sh check <path-to-.env>`
- exit 0 → proceed.
- exit 3 (drift) → tell me which keys drifted and offer to run `… update <path>`.
- exit 2 (locked) → ask me to `rbw unlock`, then re-check.
- exit 4 (no backup yet) → offer to seed it with `… update <path>`.
Never skip the check silently, and never run `rbw login`/`rbw unlock` yourself
(those take my master password via pinentry). See the `vault` skill for details.
