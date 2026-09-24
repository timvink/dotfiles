---
paths:
  - "**/*.py"
  - "**/pyproject.toml"
  - "**/requirements*.txt"
---

# Use pydantic/httpx2 instead of httpx

In Python projects, use httpx2 (https://github.com/pydantic/httpx2) as the HTTP
client instead of `httpx` for new code and newly introduced HTTP usage, unless I
say otherwise for that project. Add `httpx2` to the project's dependencies rather
than `httpx`.
