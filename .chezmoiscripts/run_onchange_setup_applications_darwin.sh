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
    rectangle
    spotify
    notion
    font-roboto
    font-fira-code
    font-meslo-for-powerlevel10k
    font-powerline-symbols
    font-hack-nerd-font
    font-3270-nerd-font
    font-caskaydia-mono-nerd-font
    firefox
    steipete/tap/codexbar
    handy
    nextcloud
    ghostty
    netbirdio/tap/netbird-ui
)

echo "Installing cask apps..."
for cask in "${CASKS[@]}"; do
    cask_name="${cask##*/}"  # strip tap prefix (e.g. steipete/tap/codexbar -> codexbar)
    if brew list --cask "$cask_name" &>/dev/null 2>&1; then
        echo "Already installed, skipping: $cask_name"
    else
        brew install --cask "$cask"
    fi
done


echo "Configuring OSX..."

# Show filename extensions by default
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Make sure to not get those annoying .DS_Store files everywhere
defaults write com.apple.desktopservices DSDontWriteNetworkStores true

# Show hidden files by default
defaults write com.apple.Finder AppleShowAllFiles true

# Disable window animations and Get Info animations
defaults write -g NSAutomaticWindowAnimationsEnabled -bool false

# Install netbird service for VPN Mesh access
if ! sudo launchctl list | grep -q netbird; then
    sudo netbird service install
    sudo netbird service start
fi
# netbird up # run this once to login