---
name: update-skill
description: Refresh a vendored skill from its recorded upstream repository while preserving deliberate local changes.
---

# Update a vendored skill

Read the skill's `source:` and `local-edits:` frontmatter. A GitHub directory URL
identifies an upstream copy; a documentation URL may only identify inspiration,
not a synchronizable skill. If there is no usable source, report that rather than
guessing a repository.

Fetch the upstream directory, including supporting files, into scratch space.
Use the GitHub contents API or a checkout; don't assume the path is `skills/<name>`.
Compare the full directory with the local version before replacing anything.

Summarize material behavior changes. An explicit update request authorizes routine
refreshes; ask only when a conflict requires choosing whether to discard a local
behavior. Preserve `source:`, `local-edits:`, licenses, and other intentional
customizations. Reapply the local edits to updated upstream content, and remove
obsolete upstream files only after checking local references.

Validate frontmatter and local links. Skills in `agents/skills/` are live through
symlinks or pi's configured path, so content edits need no apply. Additions and
removals need the chezmoi skill-link script to refresh the symlink inventory.
Stage only the intended changes when a commit is requested.

If an installed plugin duplicates a vendored skill, report the collision. Don't
change plugin configuration as an unrequested side effect of refreshing files.
