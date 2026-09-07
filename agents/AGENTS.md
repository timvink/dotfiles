<!-- Shared instructions for Claude Code, Codex, Antigravity, and pi.
     Edit this file in the chezmoi source; agent config paths link here. -->

These rules apply across projects unless explicitly overridden. Read the project's
AGENTS.md (and applicable CLAUDE.md) before working.

## Working approach

State consequential assumptions, question unnecessary complexity, and fix the
cause of a problem. Define the requested outcome and verify it with checks
proportionate to the change. Preserve existing project conventions.

Prefer Context7 for library/API documentation when available; otherwise use
official documentation. For text-only fetches of public pages, try prefixing the
URL with `https://markdown.new/`; fetch directly if it fails, and never proxy
private URLs or authenticated requests.

Use consistent domain vocabulary and searchable names. Document constraints the
code cannot express, such as units, timezones, and ownership. Avoid renaming or
splitting existing code solely to satisfy a naming preference.

## Writing

Follow `write-for-humans` for human-facing prose; load it before writing more than
a few sentences. Lead with useful information, use plain words and active
voice, and omit filler, repeated summaries, and unnecessary formatting.

## Scratch files and progress

Put standalone previews, reports, and HTML artifacts in the session scratchpad,
or `/tmp` if none exists. Tell the user the full path.

For substantial work, set `agent-note` at the start and phase changes. Use a
present-tense label around 60 characters, without trailing punctuation. Skip
quick questions and one-line edits. Never clear the note; it is safe outside tmux.

## Machine configuration and secrets

Load `chezmoi` before changing dotfiles, agent configuration, or installed tools.
Declare changes in the source repo; never hand-edit managed live files.

Load `vault` when using vault credentials, changing `.env` keys, or creating or
rotating gitignored key files. After changes, refresh and verify the vault backup
with its `env-vault-sync.sh` or `file-vault-sync.sh` helper. Reading needs no sync.
If locked, ask the user to unlock; never run `rbw login` or `rbw unlock`, or handle
the master password.

## Project tooling and worktrees

Prefer `prek` for new hook setups; retain a project's existing runner.
In a worktree, use the project's setup procedure (for example, `make setup`) and
its `.worktreeinclude` when present. Check required ignored files and dependencies;
ask only if missing setup prevents progress.

Before removing a worktree, clean up only the Docker resources created for it,
using its actual Compose project name. Remove volumes only when disposable. Do
not run global Docker pruning as routine cleanup.
