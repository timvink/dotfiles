<!-- Shared instructions for Claude Code, Codex, Antigravity, and pi.
     Edit this file in the chezmoi source; agent config paths link here. -->

These rules apply across projects unless explicitly overridden. Read the project's
AGENTS.md (and applicable CLAUDE.md) before working.

On NWF devboxes, read `~/workspace/nwf-ai-platform-infra/AGENTS.md` for the shared
VM instructions. If it does not exist, read `/etc/codex/AGENTS.md` instead.

## Working approach

State consequential assumptions, question unnecessary complexity, and fix the root
cause of a problem. Define the requested outcome and verify it with checks
proportionate to the change.

Prefer Context7 for library/API documentation when available; otherwise use
official documentation. For text-only fetches of public pages, try prefixing the
URL with `https://markdown.new/`; fetch directly if it fails.

Use consistent domain vocabulary and searchable names. Document constraints the
code cannot express, such as units, timezones, and ownership. Avoid renaming or
splitting existing code solely to satisfy a naming preference.

Use subagents whenever they help: parallel independent work, broad searches,
or keeping file dumps out of the main context.

Claude only: review critical work, or work you're unsure of, with Codex
(`codex exec`).

Commit your completed changes before ending a task. Do not leave work you made
uncommitted unless the user asks you to or a blocker prevents the commit; explain
any remaining uncommitted changes.

## Writing

For human-facing prose, lead with useful information, use plain words and active
voice, and omit filler, repeated summaries, and unnecessary formatting.

## Scratch files and progress

Put standalone previews, reports, and HTML artifacts in the session scratchpad,
or `/tmp` if none exists. Tell the user the full path.

## Machine configuration and secrets

For authenticated browsing from a headless machine, use `host-browser` when
available. It forwards `agent-browser` commands to visible Chrome sessions on
the host Mac through the devbox/homelab SSH tunnel. Use `--session NAME` with a
distinct name per agent; profiles retain logins on the Mac. Complete SSO/MFA in
the host window. File arguments and screenshot paths refer to the Mac.
See the chezmoi README for setup; an unavailable bridge needs the Mac-side
setup, not another unauthenticated browser on the headless machine.

Load `chezmoi` before changing dotfiles, agent configuration, or installed tools.
Declare changes in the source repo; never hand-edit managed live files.

Load `vault` when using vault credentials, changing secret-bearing `.env` files
(including removing their last secret), or creating or rotating gitignored
credential files.
Public, non-secret configuration such as versioned VM `<user>.env` files needs
no vault backup or unlock. After changes in scope, refresh and verify the vault
backup with its `env-vault-sync.sh` or `file-vault-sync.sh` helper. Reading needs
no sync. If `rbw` is locked, ask the user to unlock.

## Project tooling and worktrees

Prefer `prek` for new hook setups; retain a project's existing runner.
In a worktree, use the project's setup procedure (for example, `make setup`) and
its `.worktreeinclude` when present.

When removing a worktree, also clean up the Docker resources created for it. Remove volumes only when disposable.
