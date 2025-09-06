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

# Always update Homebrew for latest casks and formulae
echo "Updating Homebrew..."
brew update



# Cask programs
CASKS=(
    visual-studio-code
    dropbox
    flux
    iterm2
    rectangle
    spotify
    notion
    font-roboto
    font-fira-code
    font-meslo-for-powerlevel10k
)

echo "Installing cask apps..."
brew install --cask "${CASKS[@]}"

echo "Installing fonts..."
brew install --cask font-roboto
brew install --cask font-fira-code

echo "Configuring OSX..."

# Show filename extensions by default
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Make sure to not get those annoying .DS_Store files everywhere
defaults write com.apple.desktopservices DSDontWriteNetworkStores true

# Show hidden files by default
defaults write com.apple.Finder AppleShowAllFiles true