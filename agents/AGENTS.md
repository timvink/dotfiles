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

## Machine setup is infrastructure-as-code
Prefer declaring a change in code over running a one-off imperative command.
My dotfiles and machine configuration — shell config, `~/.gitconfig`,
`~/.claude/`, installed-tool config, packages — are managed with chezmoi, so
never hand-edit a live config file: the next `chezmoi apply` silently
overwrites it. Load the `chezmoi` skill before changing any of this.

## .env files are vault-backed
Secrets in a `.env` are mirrored into my password vault. Whenever you **change**
a `.env` (or `.env.local`, etc.) — add, edit or remove a key — refresh the vault
copy afterwards with the `vault` skill's helper (symlinked into all my agent
tools; the path below resolves the same everywhere):
`~/.local/share/chezmoi/agents/skills/vault/env-vault-sync.sh update <path-to-.env>`
Reading a secret out of a `.env` needs no sync — only writing does. If the
helper says the vault is locked, tell me; never run `rbw login`/`rbw unlock`
yourself (those take my master password via pinentry). See the `vault` skill for
the rest.

## Git worktrees
When working in a git worktree (e.g. started with `claude --worktree`) the
checkout is fresh: gitignored files are absent and dependencies aren't
installed. Before starting project work, confirm the repo provides both:
- a `.worktreeinclude` at the repo root (gitignore syntax, one path per line)
  listing gitignored files to copy in — `.env`, `.env.local`, local secrets;
- a `setup` target in the `Makefile` that prepares the environment (install
  deps, build venvs, seed config); run it with `make setup`.
If either is missing, stop and ask the user to add it before continuing.

## Project-level AGENTS.md
When a repo ships an `AGENTS.md`, follow it exactly as if it were a `CLAUDE.md`
— it carries the same authority. (This matters because Claude Code only loads
`CLAUDE.md` on its own; Codex only loads `AGENTS.md`.)

