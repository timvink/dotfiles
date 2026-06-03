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
- I use my ZSA Voyager with custom key mappings (Hyper is a left-thumb hold there, a left-pinky `caps` hold on the Mac — either way Hyper lives on the left hand, so the app launcher below is all left-hand keys).

Hyper + key opens an app (repeat within 1.5s cycles its windows). All keys are
left-hand so the right hand stays free for the mouse. Mnemonics:

| Key | App | Mnemonic |
|-----|-----|----------|
| `A` | Spotify | "Aaaah" — music |
| `S` | Teams | think "Slack" (chat) |
| `D` | Ghostty | "Dev" |
| `F` | Firefox | Firefox |
| `W` | Signal | "Whisper" (Open Whisper Systems) |
| `E` | Finder | "Explorer" |
| `R` | Notion | "Records" |
| `T` | Todoist | "Todo" |


Apps:

- Terminal: `zsh` on Ghostty with starship.
- Editors: tmux and neovim
- Tiling manager: Rectangle

Theme: [catppuccin](https://github.com/orgs/catppuccin/repositories?type=all)!
