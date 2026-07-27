# Reproduce my claude setup

## MCP servers

Declared in `.chezmoiscripts/run_onchange_after_setup-claude-mcp.sh.tmpl` and
registered automatically on `chezmoi apply` — add or change a server there, not
with a one-off `claude mcp add`. The same set is mirrored for Codex in
`dot_codex/modify_private_config.toml`.

Definitions only: OAuth tokens live in Claude's own credential store, so each
hosted server still needs a one-time `claude mcp login <name>` (or an in-session
`/mcp` auth) per machine.

Note that context7 uses a dedicated OAuth endpoint (`/mcp/oauth`, not `/mcp`)
per <https://context7.com/docs/howto/oauth> — keyless, so no API key in this repo.
