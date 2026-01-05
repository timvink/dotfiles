# How to use python

Python repos standard: we use `uv` and `pyproject.toml` in all Python repos. Prefer `uv sync` for env and dependency resolution. 
Do not introduce `pip` venvs, Poetry, or `requirements.txt` unless asked. Examples of using `uv`:

- Managing requirements: `uv add <package>` and `uv remove <package>`
- Updating the venv: `uv sync`
- Running a python script: `uv run python <path>`. This will update the venv and activate it.
- Updating the python version can be done using `uv python pin <version>`

Use strong types, prefer type hints everywhere, keep models explicit instead of loose dicts or strings.