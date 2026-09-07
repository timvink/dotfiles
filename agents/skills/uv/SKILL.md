---
name: uv
description: Choose uv workflows for Python projects, standalone scripts, and tools; includes the user's ty preference for new type-checking setups. Respect existing project tooling.
---

# Python tooling

Prefer uv for new Python work. In existing projects, follow their lockfile,
instructions, and configured tooling; don't migrate Poetry, PDM, or another
workflow as a side effect of an unrelated task.

| Task | Command |
| --- | --- |
| Run within a uv project | `uv run <command>` |
| Install locked project dependencies | `uv sync` |
| Add or remove a project dependency | `uv add <package>` / `uv remove <package>` |
| Run a standalone script with dependencies | `uv run --with <package> script.py` |
| Declare script dependencies inline | `uv add --script script.py <package>` |
| Run a standalone CLI tool | `uvx <package> <args>` |
| Run with a specific Python version | `uv run --python 3.12 script.py` |

Use the project's pinned tools through `uv run`. Use `uvx` for tools that don't
need the project's environment. In uv projects, avoid direct pip installs and
manual environment activation. Keep legacy requirements workflows when needed;
don't introduce new requirements files in a uv project.

Persistent tool installation belongs in the chezmoi package setup. Temporary
execution does not require adding a machine-wide installation.

## Type checking

Keep the project's existing checker. Prefer ty when adding type checking to a
new project: `uv run ty check` when it is a project dependency, or `uvx ty check`
for a one-off check. Adding this skill does not configure a language server.

Fix type errors where practical. When an upstream typing limitation requires an
ignore, scope it to the checker's specific rule and explain why it is needed.
Don't replace another checker's configuration or suppressions automatically.

## Dependency changes

Respect existing cooldown and audit policies. Don't add a cooldown merely because
you are working in Python. After changing dependencies, use the project's audit
check (or `uv audit` if supported by its installed uv version). Address findings
within scope; report blockers rather than upgrading unrelated dependencies in an
unbounded loop.

For uncertain options, consult installed help or official Astral documentation
through Context7 when available.
