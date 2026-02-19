---
description:
  Commit staged and unstaged changes, then push to the remote. Use when the
  user asks to commit and push, or to "ship" / "save" their work.
---

# commit-and-push

Commit all changes and push to the remote branch.

## Instructions

1. Run `git status` and `git diff` in parallel to review changes.
2. Stage relevant files by name (avoid `git add -A` or `git add .` unless safe).
3. Write a concise commit message (1–2 sentences) that focuses on *why*, not *what*.
   - Use imperative mood ("add", "fix", "update", not "added", "fixed").
   - Do **not** include a `Co-Authored-By` trailer.
4. Commit using a HEREDOC so formatting is preserved:
   ```
   git commit -m "$(cat <<'EOF'
   Your message here
   EOF
   )"
   ```
5. Push to the remote: `git push`.
6. Report the commit hash and confirm the push succeeded.

## Rules

- Never use `--no-verify`.
- Never force-push unless the user explicitly requests it.
- Never amend a published commit unless explicitly asked.
- Do **not** add a `Co-Authored-By` line to any commit.
