# dotfiles

Tim Vink's personal dotfiles managed by [chezmoi.io](https://www.chezmoi.io/).

On a new machine, install `chezmoi` and:

```bash
chezmoi init --apply https://github.com/timvink/dotfiles.git
```

## Setup

My main OS is MacOS, but I try to keep things like keybindings generic as I use linux and windows as well.

Keybindings:

- On my Mac internal keyboard I use [karabiner elements](https://karabiner-elements.pqrs.org/) to map my caps lock key to `ESC` (tapped) and hyper (`shift`+`cmd`+`alt`+`ctrl`) (held more than 250ms).
- Otherwise, I use my ZSA Voyager.

Apps:

- Terminal: `zsh` on Alacritty with starship. Additional packages:
    - btop (computer stats)
    - eza (`ls`)
- Editors: VSCode and neovim
- Tiling manager: Rectangle (will move to aerospace)

Theme: [catppuccin](https://github.com/orgs/catppuccin/repositories?type=all)!
