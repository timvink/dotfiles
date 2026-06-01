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

## Git worktrees
When working in a git worktree (e.g. started with `claude --worktree`) the
checkout is fresh: gitignored files are absent and dependencies aren't
installed. Before starting project work, confirm the repo provides both:
- a `.worktreeinclude` at the repo root (gitignore syntax, one path per line)
  listing gitignored files to copy in — `.env`, `.env.local`, local secrets;
- a `setup` target in the `Makefile` that prepares the environment (install
  deps, build venvs, seed config); run it with `make setup`.
If either is missing, stop and ask the user to add it before continuing.
