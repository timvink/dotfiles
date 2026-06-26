---
name: update-skill
description: Update a vendored skill to its latest upstream version. Use when the user asks to update, refresh, or re-sync a skill that was copied in from an external repo (e.g. anthropics/skills). Works by reading the skill's own `source:` URL.
---

# Updating a vendored skill

Some skills in this repo are **vendored** — copied from an upstream repo rather
than installed via a marketplace plugin. Each one records where it came from in
its `SKILL.md` frontmatter:

```yaml
source: https://github.com/<owner>/<repo>/tree/<branch>/<dir>
```

To update one, find that URL and re-sync from it. Skills live in the chezmoi
source at `~/.local/share/chezmoi/agents/skills/<name>/`, symlinked into
`~/.claude/skills`, `~/.codex/skills` and `~/.gemini/config/skills` — so editing
the repo copy is instantly live in every tool.

## Steps

1. **Find the source URL.** Search the skill's frontmatter:

   ```bash
   grep -m1 '^source:' ~/.local/share/chezmoi/agents/skills/<name>/SKILL.md
   ```

   If there is no `source:` line, the skill is not vendored (it may be a
   marketplace plugin or hand-written) — stop and tell the user; don't guess a URL.

2. **Translate the URL to a fetchable form.** A source URL has the shape
   `https://github.com/<owner>/<repo>/tree/<branch>/<dir>`. Note `<dir>` is the
   skill's path within that repo and is **not** always `skills/<name>` — e.g. the
   anthropics skills live at `skills/<name>`, but the polars skill lives at just
   `polars`. Map `<dir>` (whatever it is) to:
   - Directory listing (to discover every file, including `references/`, `scripts/`):
     `https://api.github.com/repos/<owner>/<repo>/contents/<dir>?ref=<branch>`
   - Raw file content:
     `https://raw.githubusercontent.com/<owner>/<repo>/<branch>/<dir>/<path>`

   Recurse the API listing into subdirectories so multi-file skills are fully covered.

3. **Diff before overwriting.** Fetch upstream `SKILL.md`, diff it against the local
   copy, and show the user what changed. Don't silently replace — a rewrite may
   change the skill's behaviour.

4. **Replace all files**, then **re-add the `source:` line** to the frontmatter
   (upstream files won't contain it — it's our addition). Keep any other local
   additions intentional and call them out.

5. **No `chezmoi apply` needed for edits.** Skills are symlinked, so overwriting
   the repo files under `agents/skills/<name>/` is already live in every tool.
   (`chezmoi apply` is only needed when adding a *brand-new* skill, to create its
   symlinks.)

## Notes

- Stage only the files you changed when committing (the repo may hold unrelated WIP).
- If a skill exists both as a vendored copy *and* an enabled marketplace plugin of
  the same name, that's a collision — disable the plugin
  (`enabledPlugins` in `~/.claude/settings.json`) so there's one authoritative copy.
