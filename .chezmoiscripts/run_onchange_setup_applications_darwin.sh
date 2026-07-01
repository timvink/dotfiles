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
    rectangle
    spotify
    notion
    font-roboto
    font-fira-code
    font-powerline-symbols
    font-hack-nerd-font
    font-3270-nerd-font
    font-caskaydia-mono-nerd-font
    font-jetbrains-mono-nerd-font
    firefox
    steipete/tap/codexbar
    handy
    nextcloud
    ghostty
    netbirdio/tap/netbird-ui
    signal
    whatsapp
)

# Trust the netbird tap so brew loads its (third-party) cask/formula
# definitions without an interactive prompt. Required for the netbird-ui
# cask below, and stops later `brew` runs from refusing to load the tap.
brew trust netbirdio/tap
# Same for the codexbar cask (steipete's tap) in CASKS above — once tap-trust
# becomes mandatory, a fresh `brew install --cask` would otherwise refuse it.
brew trust --cask steipete/tap/codexbar

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

# Hold a key to repeat it instead of popping the accent/diacritic picker, so
# holding hjkl scrolls (vim) instead of offering ĵ. Key-repeat *speed* is left
# at the System Settings default on purpose. Takes effect after logout/restart.
defaults write -g ApplePressAndHoldEnabled -bool false

# Show filename extensions by default
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Make sure to not get those annoying .DS_Store files everywhere
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Show hidden files by default
defaults write com.apple.Finder AppleShowAllFiles true

# Open new Finder windows in ~/Downloads instead of "Recents".
# PfLo = "Other" location; NewWindowTargetPath points it at the folder.
defaults write com.apple.finder NewWindowTarget -string "PfLo"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/Downloads/"
killall Finder 2>/dev/null || true

# Disable window animations and Get Info animations
defaults write -g NSAutomaticWindowAnimationsEnabled -bool false

# Menu bar: pack more status icons into the bar.
# macOS has no "max icons" knob — when the focused app needs room for its menu
# titles it just hides the right-most menu-bar extras. The only native lever
# that lets MORE icons fit is shrinking the per-icon spacing/padding (each
# defaults to ~16pt). Lower = tighter = more icons fit before macOS hides them.
# These two keys only take effect when written to the *per-host* global domain
# (ByHost), hence -currentHost. Raise toward 16 to loosen; ~6 is about as tight
# as stays comfortable.
defaults -currentHost write -globalDomain NSStatusItemSpacing -int 8
defaults -currentHost write -globalDomain NSStatusItemSelectionPadding -int 6
# Repaint the menu bar now; a full logout/login guarantees it everywhere.
killall SystemUIServer 2>/dev/null || true
killall ControlCenter 2>/dev/null || true

# Install netbird service for VPN Mesh access
if ! sudo launchctl list | grep -q netbird; then
    sudo netbird service install
    sudo netbird service start
fi
# netbird up # run this once to login