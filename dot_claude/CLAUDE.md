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

## End-of-turn input signal
A tmux hook flips my tab indicator to red ("your input needed") instead of yellow
("done") when your final message ends with a question. So phrase your turn ending
to match what you actually need:
- When you end a turn genuinely waiting on me — you asked something or presented a
  choice and can't sensibly proceed until I answer — make the **last line a
  question ending in "?"**.
- When you're just reporting completed work, or offering an optional next step you
  don't need answered, **end on a statement, not a question**, so the tab reads as
  done.

This only governs the final line. Don't contort your writing — but don't tack a
reflexive "Want me to…?" onto a turn that's really finished, and don't end a
genuine hand-back-to-me on a flat statement. Tool-collected input (AskUserQuestion,
ExitPlanMode, permission prompts) already signals separately — no question needed.

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
