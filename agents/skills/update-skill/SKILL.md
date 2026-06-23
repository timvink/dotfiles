---
name: update-skill
description: Update a vendored skill to its latest upstream version. Use when the user asks to update, refresh, or re-sync a skill that was copied in from an external repo (e.g. anthropics/skills). Works by reading the skill's own `source:` URL.
---

# Updating a vendored skill

Some skills in this repo are **vendored** — copied from an upstream repo rather
than installed via a marketplace plugin. Each one records where it came from in
its `SKILL.md` frontmatter:

```yaml
source: https://github.com/anthropics/skills/tree/main/skills/<name>
```

To update one, find that URL and re-sync from it. Skills live in the chezmoi
source at `~/.local/share/chezmoi/dot_claude/skills/<name>/`.

## Steps

1. **Find the source URL.** Search the skill's frontmatter:

   ```bash
   grep -m1 '^source:' ~/.local/share/chezmoi/dot_claude/skills/<name>/SKILL.md
   ```

   If there is no `source:` line, the skill is not vendored (it may be a
   marketplace plugin or hand-written) — stop and tell the user; don't guess a URL.

2. **Translate the URL to a fetchable form.** A `tree/main/skills/<name>` URL maps to:
   - Directory listing (to discover every file, including `reference/`, `scripts/`):
     `https://api.github.com/repos/<owner>/<repo>/contents/skills/<name>`
   - Raw file content:
     `https://raw.githubusercontent.com/<owner>/<repo>/main/skills/<name>/<path>`

   Recurse the API listing into subdirectories so multi-file skills are fully covered.

3. **Diff before overwriting.** Fetch upstream `SKILL.md`, diff it against the local
   copy, and show the user what changed. Don't silently replace — a rewrite may
   change the skill's behaviour.

4. **Replace all files**, then **re-add the `source:` line** to the frontmatter
   (upstream files won't contain it — it's our addition). Keep any other local
   additions intentional and call them out.

5. **Apply:** `chezmoi apply` to update the live `~/.claude/skills/<name>/`.

## Notes

- Stage only the files you changed when committing (the repo may hold unrelated WIP).
- If a skill exists both as a vendored copy *and* an enabled marketplace plugin of
  the same name, that's a collision — disable the plugin
  (`enabledPlugins` in `~/.claude/settings.json`) so there's one authoritative copy.
