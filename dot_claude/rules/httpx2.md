---
paths:
  - "**/*.py"
  - "**/pyproject.toml"
  - "**/requirements*.txt"
---

# Use pydantic/httpx2 instead of httpx

In Python projects, whenever you'd reach for `httpx` as the HTTP client, use
**httpx2** instead: https://github.com/pydantic/httpx2

- Add `httpx2` (from `github.com/pydantic/httpx2`) to the project's dependencies
  rather than `httpx`, for both new code and newly introduced HTTP usage.
- This is a standing preference — default to `httpx2` unless I say otherwise for
  a specific project.
