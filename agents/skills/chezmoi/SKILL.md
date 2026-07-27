---
name: chezmoi
description: >-
  Change this machine's setup the infrastructure-as-code way, through the
  chezmoi source repo, instead of hand-editing live config. Use whenever a task
  would modify dotfiles or machine configuration — shell config (`~/.zshrc`,
  `~/.bashrc`), `~/.gitconfig`, `~/.claude/` or other agent-tool config, SSH
  config, tmux, installed packages, launch agents — or when asked where a
  config file "really" lives, or to install a tool persistently.
---

# Machine setup via chezmoi

Dotfiles and machine configuration are managed with
[chezmoi](https://www.chezmoi.io/). The files in `$HOME` are **generated
output**, not the source.

## The rule

Never hand-edit a managed live file. `chezmoi apply` regenerates it from the
source, silently discarding the edit — so a direct change looks like it worked
and then vanishes at an unpredictable later moment. Edit the source, then apply.

The same instinct applies beyond dotfiles: prefer declaring a change in the repo
over running a one-off imperative command. A package installed by hand is gone
on the next machine; one added to the package script is reproducible.

## Workflow

```bash
chezmoi source-path ~/.gitconfig   # where does this file come from?
chezmoi cd                         # enter the source repo (~/.local/share/chezmoi)
# ...edit the source file, e.g. dot_gitconfig.tmpl...
chezmoi diff ~/.gitconfig          # preview what apply would change
chezmoi apply ~/.gitconfig         # regenerate just this file
```

Work on a single target path where you can — a bare `chezmoi apply` regenerates
everything and makes it harder to see what your change did.

If `source-path` errors, the file isn't managed yet. Adding it is `chezmoi add
<path>`, which copies the current file into the repo under its encoded name.

## Reading the source repo

Source filenames encode target attributes: `dot_` → a leading `.`, `private_` →
mode 600, `executable_` → `+x`, `.tmpl` → rendered as a Go template, `symlink_`
→ a symlink. So `dot_config/private_foo/executable_bar.sh.tmpl` becomes
`~/.config/foo/bar.sh`, mode 700, templated. `run_onchange_*` scripts re-run
when their content changes; `.chezmoitemplates/` holds partials shared by
several targets.

The repo has its own `CLAUDE.md` documenting layout and conventions — it loads
when you work in there, so read it rather than guessing.

## Committing

The repo may hold unrelated work in progress. Stage only the files your change
touched; never `git add -A`. Committing is the user's call unless they've asked
for it.
