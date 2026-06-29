#!/bin/sh

echo "Setting up environment for macOS..."

# Install Homebrew if not installed
if ! command -v brew &> /dev/null
then
    echo "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "Homebrew found. Skipping installation."
fi

# Update homebrew recipes
brew update

# Install GNU core utilities (those that come with OS X are outdated)
brew install coreutils

# Install GNU `find`, `locate`, `updatedb`, and `xargs`, g-prefixed
brew install findutils

# Managing dotfiles
brew install chezmoi

# The very cool `eza`, a colorized `ls`
# Note I have an alias setup in my .zshrc file but not in .bashrc
brew install eza

# Install some brew packages
echo "Installing packages..."
PACKAGES=(
  git
  jq
  tmux
  tree
  wget
  bat
  vim
  rsync
  neovim
  fd # A simple, fast and user-friendly alternative to 'find'
  btop # Better than htop
  fastfetch # neofetch-style system info; config in ~/.config/fastfetch
  ripgrep # required for lazyvim fuzzy file search
  fzf # fuzzy finder: ctrl-r history, ctrl-t files, **<tab> completion
  gh # GitHub CLI (used by claude skills, PRs, gh api)
  lazygit # git TUI; LazyVim binds <leader>gg to it
  lazydocker
  uv
  starship
  zsh
  zsh-completions
  zsh-fast-syntax-highlighting
  zsh-autocomplete
  diff-so-fancy
  visidata
  gnupg
  pinentry-mac
  rbw # Bitwarden/Vaultwarden CLI; config managed by chezmoi (Library/Application Support/rbw on macOS, ~/.config/rbw on Linux)
  supabase/tap/supabase
  scw
  watch
  pngpaste # clipboard image -> PNG, used by img-clip.nvim in neovim
  imagemagick # `magick` CLI; snacks.image uses it to render .png/.jpg previews in nvim
  wireguard-tools # wg/wg-quick for the ProtonVPN tunnel (see the `protonvpn` CLI)
  wireguard-go # userspace WireGuard backend (macOS has no kernel module)
  vde # provides `dpipe`, used by devmount() to reverse-mount ~/Downloads onto the devbox via sshfs
)
brew install ${PACKAGES[@]}

echo "Cleaning up..."
brew cleanup

# Install VSCode extensions

VSCODE_EXTENSIONS=(
  ms-python.python
  joshmu.periscope
  charliermarsh.ruff
  vscodevim.vim
  redhat.vscode-yaml
  catppuccin.catppuccin-vsc
  astral-sh.ty
)

# Install VSCode extensions (skip silently if the `code` CLI isn't on PATH —
# e.g. a fresh box where VSCode's shell command hasn't been registered yet).
if command -v code >/dev/null 2>&1; then
    echo "Installing VSCode extensions..."
    for ext in "${VSCODE_EXTENSIONS[@]}"; do
        code --install-extension "$ext" --force
    done
else
    echo "VSCode 'code' CLI not found on PATH; skipping extension install."
fi

# Install Claude Code
if ! brew list --cask claude-code >/dev/null 2>&1; then
    brew install --cask claude-code
fi

# Install agy (antigravity CLI)
if ! command -v agy >/dev/null 2>&1; then
    curl -fsSL https://antigravity.google/cli/install.sh | bash
fi
