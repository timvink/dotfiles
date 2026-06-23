<!-- Shared global agent instructions. Symlinked from this repo's agents/AGENTS.md
     to ~/.claude/CLAUDE.md (Claude Code) and ~/.codex/AGENTS.md (Codex). Edit
     here. Tool-specific rules live in ~/.claude/rules/ and ~/.codex/rules/. -->

These rules apply to every task in this project unless explicitly overridden.
Bias: caution over speed on non-trivial work. Use judgment on trivial tasks.

## Rule 1 — Think Before Coding
State assumptions explicitly. If uncertain, ask rather than guess.
Present multiple interpretations when ambiguity exists.
Push back when a simpler approach exists.
Stop when confused. Name what's unclear.
Fix things from first principles. Find the root cause and fix that, instead of applying a cheap bandaid.
Always use Context7 MCP when you need library/API documentation.

## Rule 2 — Simplicity First
Minimum code that solves the problem. Nothing speculative.
No features beyond what was asked. No abstractions for single-use code.
Test: would a senior engineer say this is overcomplicated? If yes, simplify.
Clean up unused code ruthlessly. If a function no longer needs a parameter or a helper is dead, delete it and update the callers instead of letting the junk linger.

## Rule 3 — Goal-Driven Execution
Define success criteria. Loop until verified.
Don't follow steps. Define success and iterate.
Strong success criteria let you loop independently.

## HTML artifacts & scratch files
When I ask for an HTML artifact — a standalone file just for me to open and look
at, not part of a project — create it under a temp dir (`/tmp`), never the home
or project directory. Same for other one-off preview/report files. They're
disposable; don't clutter tracked or working trees with them. Tell me the path.

## End-of-turn input signal
A tmux hook reads your final line: ending in "?" flips my tab to red ("input
needed"), else yellow ("done"). End with "?" only when you genuinely can't proceed
without my answer. Optional next steps — even interesting ones — get stated, not
asked: not "Want me to pull the slowest turns?" but "Next if useful: pull the
slowest turns." Litmus: if you'd be fine stopping here, state it. Don't contort your
writing or tack a reflexive "Want me to…?" onto finished work. Tool prompts
(AskUserQuestion, ExitPlanMode, permissions) signal separately — no question needed.

## Machine setup via chezmoi
Dotfiles and machine configuration are managed with chezmoi. Any change to the
machine setup — shell config, `~/.gitconfig`, `~/.claude/`, installed-tool config,
etc. — must be made in the chezmoi source repo, never by hand-editing the live
file (a direct edit is silently overwritten on the next `chezmoi apply`).
Run `chezmoi cd` to enter the repo (source root: `~/.local/share/chezmoi`).
Use `chezmoi source-path <file>` to find a file's source, edit that source
(e.g. `dot_gitconfig.tmpl`), then `chezmoi apply` to update the live file. When
committing, stage only the files you changed — the repo may hold unrelated WIP.

## Git worktrees
When working in a git worktree (e.g. started with `claude --worktree`) the
checkout is fresh: gitignored files are absent and dependencies aren't
installed. Before starting project work, confirm the repo provides both:
- a `.worktreeinclude` at the repo root (gitignore syntax, one path per line)
  listing gitignored files to copy in — `.env`, `.env.local`, local secrets;
- a `setup` target in the `Makefile` that prepares the environment (install
  deps, build venvs, seed config); run it with `make setup`.
If either is missing, stop and ask the user to add it before continuing.
