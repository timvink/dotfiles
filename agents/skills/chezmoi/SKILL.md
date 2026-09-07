---
name: chezmoi
description: Change managed dotfiles, agent configuration, installed packages, or machine setup through the chezmoi source repo. Also locate the source of a live config file.
---

# Machine setup via chezmoi

Managed files in the home directory are generated output. Edit their source and
apply the affected targets; declare persistent package changes in the setup scripts.

```sh
chezmoi source-path ~/.gitconfig
# Edit the returned source path.
chezmoi diff ~/.gitconfig
chezmoi apply ~/.gitconfig
```

Prefer a targeted apply so unrelated machine setup does not run. If `source-path`
fails, investigate whether the file is unmanaged; `chezmoi add <path>` imports an
existing file when adding it to management is part of the task.

Read the source repo's `AGENTS.md` for conventions and package-script locations.
Apps that mutate their own config need `modify_` scripts that preserve runtime
state. Skills under `agents/skills/` are read directly through links or configured
paths; editing their content needs no apply.

Source names encode attributes: `dot_` adds a leading dot, `private_` restricts
permissions, `executable_` adds execution permission, `symlink_` creates a link,
and `.tmpl` renders a template. `run_onchange_*` scripts rerun when their rendered
content changes; `.chezmoitemplates/` holds shared partials.

Stage only intended files. Commit when the user requests it; never include
unrelated work with `git add -A`.
