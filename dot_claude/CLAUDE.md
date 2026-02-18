## Quick Obligations

| Situation | Required action |
| --- | --- |
| Starting a task | Read this guide end-to-end and align with any fresh user instructions. |
| Tool or command hangs | If a command runs longer than 5 minutes, stop it, capture logs, and check with the user. |
| Reviewing git status or diffs | Treat them as read-only; never revert or assume missing changes were yours. |
| Adding a dependency | Research well-maintained options and confirm fit with the user before adding. |

## Mindset & Process

- THINK A LOT PLEASE.
- **No breadcrumbs**. If you delete or move code, do not leave a comment in the old place. No "// moved to X", no "relocated". Just remove it.
- **Think hard, do not lose the plot**.
- Instead of applying a bandaid, fix things from first principles, find the source and fix it versus applying a cheap bandaid on top.
- When taking on new work, follow this order:
  1. Think about the architecture.
  1. Research official docs, blogs, or papers on the best architecture.
  1. Review the existing codebase.
  1. Compare the research with the codebase to choose the best fit.
  1. Implement the fix or ask about the tradeoffs the user is willing to make.
- Write idiomatic, simple, maintainable code. Always ask yourself if this is the most simple intuitive solution to the problem.
- Leave each repo better than how you found it. If something is giving a code smell, fix it for the next person.
- Clean up unused code ruthlessly. If a function no longer needs a parameter or a helper is dead, delete it and update the callers instead of letting the junk linger.
- **Search before pivoting**. If you are stuck or uncertain, do a quick web search for official docs or specs, then continue with the current approach. Do not change direction unless asked.
- use context7
- If code is very confusing or hard to understand:
  1. Try to simplify it.
  1. Add an ASCII art diagram in a code comment if it would help.

# How to use python

Python repos standard: we use `uv` and `pyproject.toml` in all Python repos. Prefer `uv sync` for env and dependency resolution. 
Do not introduce `pip` venvs, Poetry, or `requirements.txt` unless asked. Examples of using `uv`:

- Managing requirements: `uv add <package>` and `uv remove <package>`
- Updating the venv: `uv sync`
- Running a python script: `uv run python <path>`. This will update the venv and activate it.
- Updating the python version can be done using `uv python pin <version>`

Use the `uv` skill when using python. When the code base uses type hinting, use the `ty` skill.

# Using Github Actions

Always check this file to find the latest version of a github action you might want to use: https://raw.githubusercontent.com/timvink/actions-latest/refs/heads/main/versions.txt
