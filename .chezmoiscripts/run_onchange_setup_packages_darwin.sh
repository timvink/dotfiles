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

# Install Homebrew packages
brew install bat 

# Update homebrew recipes
brew update

# Install GNU core utilities (those that come with OS X are outdated)
brew install coreutils

# Install GNU `find`, `locate`, `updatedb`, and `xargs`, g-prefixed
brew install findutils

# The much faster `ag` command
brew install the_silver_searcher

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
  neovim
  fd # A simple, fast and user-friendly alternative to 'find'
  btop # Better than htop
  ripgrep # required for lazyvim fuzzy file search
  lazydocker
  uv
  starship
  zsh
  zsh-completions
  zsh-fast-syntax-highlighting
  zsh-autocomplete
  diff-so-fancy
)
brew install ${PACKAGES[@]}

echo "Cleaning up..."
brew cleanup

# Install VSCode extensions

echo "Installing VSCode extensions..."
VSCODE_EXTENSIONS=(
  ms-python.python
  periscope
  github.copilot
  github.copilot-chat
  ruff
  vscodevim.vim
  redhat.vscode-yaml
)