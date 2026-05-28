# dotfiles

Tim Vink's personal dotfiles managed by [chezmoi.io](https://www.chezmoi.io/).

On a new machine, install `chezmoi` and:

```bash
chezmoi init --apply https://github.com/timvink/dotfiles.git
```

## Setup

My main OS is MacOS, but I try to keep things like keybindings generic as I use linux and windows as well.

Keybindings:

- I have a lot of keybindings setup. Mainly alt + hjkl to navigate consistently in VSCode, Neovim, Firefox and tmux. 
- On my Mac internal keyboard I use [karabiner elements](https://karabiner-elements.pqrs.org/) for key mappings. For example, I've mapped my caps lock key to `ESC` (tapped) and hyper (`shift`+`cmd`+`alt`+`ctrl`) (held more than 250ms).
- I use my ZSA Voyager with custom key mappings.

Apps:

- Terminal: `zsh` on Ghostty with starship.
- Editors: tmux and neovim
- Tiling manager: Rectangle

Theme: [catppuccin](https://github.com/orgs/catppuccin/repositories?type=all)!
