<!-- Shared global agent instructions. Symlinked from this repo's agents/AGENTS.md
     to ~/.claude/CLAUDE.md (Claude Code), ~/.codex/AGENTS.md (Codex) and
     ~/.gemini/GEMINI.md (Antigravity / the agy CLI). Edit here. This is the ONLY
     prose-instruction channel Codex reads, so anything ALL tools must follow
     belongs here. Claude-only or path-scoped rules can go in ~/.claude/rules/
     instead (Codex has no prose-rules dir; its ~/.codex/rules/ is a
     command-approval store, not instructions). -->

These rules apply to every task, in every project, unless explicitly overridden.
Bias: caution over speed on non-trivial work. Use judgment on trivial tasks.

## Rule 1 — Think Before Coding
State assumptions explicitly. Push back when a simpler approach exists.
Fix things from first principles. Find the root cause and fix that, instead of applying a cheap bandaid.
Always use Context7 MCP when you need library/API documentation.

## Rule 2 — Goal-Driven Execution
Define success criteria. Loop until verified.
Don't follow steps. Define success and iterate.
Strong success criteria let you loop independently.

## HTML artifacts & scratch files
When I ask for an HTML artifact — a standalone file just for me to open and look
at, not part of a project — write it to the session scratchpad dir your tool
gives you, else `/tmp`. Never the home or project directory. Same for other
one-off preview/report files: they're disposable, don't clutter tracked or
working trees with them. Always tell me the full path — the scratchpad is
per-session, so I can't guess where it went.

## End-of-turn input signal
A tmux hook reads your final line: ending in "?" flips my tab to red ("input
needed"), else yellow ("done"). End with "?" only when you genuinely can't proceed
without my answer. Optional next steps — even interesting ones — get stated, not
asked: not "Want me to pull the slowest turns?" but "Next if useful: pull the
slowest turns." Litmus: if you'd be fine stopping here, state it. Don't contort your
writing or tack a reflexive "Want me to…?" onto finished work. Tool prompts
(AskUserQuestion, ExitPlanMode, permissions) signal separately — no question needed.

## Per-tab progress note (tmux)
The tab dot says *whether* you are working; a note next to it says *what*. That
note is the only thing separating five simultaneously-working agents in my
prefix+o overview, so set it with `agent-note` when you start real work, and
again at each phase change:

    agent-note "reading the tmux overview renderer"
    agent-note "hook wired; running the checks"

Present tense, around 60 characters, no trailing punctuation — it is a label, not
a sentence. There is room for more (the overview wraps it), but a note you have to
read rather than glance at defeats the point. Two to four over a task is about
right; skip it entirely for quick
questions and one-line edits. Never clear it: the last note is what tells me what
happened while I was away, and starting or ending a session clears it for me.
No-op outside tmux, so it is always safe to call.

## Machine setup is infrastructure-as-code
Prefer declaring a change in code over running a one-off imperative command.
My dotfiles and machine configuration — shell config, `~/.gitconfig`,
`~/.claude/`, installed-tool config, packages — are managed with chezmoi, so
never hand-edit a live config file: the next `chezmoi apply` silently
overwrites it. Load the `chezmoi` skill before changing any of this.

## .env files and key files are vault-backed
Secrets in a `.env` are mirrored into my password vault. Whenever you **change**
a `.env` (or `.env.local`, etc.) — add, edit or remove a key — refresh the vault
copy afterwards with the `vault` skill's helper (symlinked into all my agent
tools; the path below resolves the same everywhere):
`~/.local/share/chezmoi/agents/skills/vault/env-vault-sync.sh update <path-to-.env>`
Reading a secret out of a `.env` needs no sync — only writing does. If the
helper says the vault is locked, tell me; never run `rbw login`/`rbw unlock`
yourself (those take my master password via pinentry). See the `vault` skill for
the rest.

Gitignored **key files** — signing keystores, SSH/TLS private keys,
service-account JSON — get the same treatment from the sibling helper
`file-vault-sync.sh` (`update` / `check` / `restore`, up to ~7 KB). If you create
or rotate one, back it up in the same pass: unlike a password these cannot be
re-read from anywhere, so an unbacked key file is a single laptop away from
gone. See the `vault` skill.

## Git worktrees
When working in a git worktree (e.g. started with `claude --worktree`) the
checkout is fresh: gitignored files are absent and dependencies aren't
installed. Before starting project work, confirm the repo provides both:
- a `.worktreeinclude` at the repo root (gitignore syntax, one path per line)
  listing gitignored files to copy in — `.env`, `.env.local`, local secrets;
- a `setup` target in the `Makefile` that prepares the environment (install
  deps, build venvs, seed config); run it with `make setup`.
If either is missing, stop and ask the user to add it before continuing.

Clean up when you're done. Everything `make setup` installs lives inside the
worktree and dies with the directory — docker's state is the exception. Compose
names its project after the worktree directory, so each worktree that ran a dev
stack or a build leaves its own containers, images and volumes on a daemon that
`git worktree remove` never touches, and disk on my dev machine is limited. From
inside the worktree, *before* removing it (a no-op if nothing ever ran):
`docker compose down --rmi local --volumes --remove-orphans`
Never reach for `docker system prune -a` instead — the daemon is shared with
every other project and parallel session, so a global prune throws away their
images too. `docker system df` shows what is really using the space, and when it
is the layer cache that fills the disk, `docker builder prune` is the one global
sweep that is safe — cache only, so nobody loses work, they just build cold once.

## Project-level AGENTS.md
When a repo ships an `AGENTS.md`, follow it exactly as if it were a `CLAUDE.md`
— it carries the same authority. (This matters because Claude Code only loads
`CLAUDE.md` on its own; Codex only loads `AGENTS.md`.)

