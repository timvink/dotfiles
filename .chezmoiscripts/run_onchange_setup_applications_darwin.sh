#!/bin/sh

# Homebrew 6 turned "ask mode" on by default: `brew install` prints its plan and
# then blocks on "Do you want to proceed? [y/n]" whenever the plan pulls in
# dependencies or dependents beyond what was named. That makes an unattended
# setup script sit there waiting for keystrokes -- once per install call. Brew
# skips the prompt when there is no TTY, so this only bites when `chezmoi apply`
# is run from a real terminal, which is the normal case.
#
# HOMEBREW_NO_ASK disables ask mode without changing what brew actually does.
# Deliberately NOT HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK (which brew's own hint
# suggests): that silences the prompt by *skipping* the dependent upgrades and
# broken-linkage repairs, leaving the machine subtly stale.
export HOMEBREW_NO_ASK=1
# Drop the "Hide these hints with..." advice blocks from the log.
export HOMEBREW_NO_ENV_HINTS=1

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
        # --adopt takes ownership of an app that is already in /Applications but
        # was NOT installed by brew (installed by hand, or by the app's own
        # updater). Without it brew aborts the whole script with "It seems there
        # is already an App at '/Applications/<X>.app'", which is how a single
        # hand-installed app blocks every later step of `chezmoi apply`.
        brew install --cask --adopt "$cask"
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

# Install netbird service for VPN Mesh access. Guard on the LaunchDaemon plist
# instead of `sudo launchctl list`: the plist is world-readable, so an already
# configured machine needs no sudo at all and `chezmoi apply` runs to completion
# non-interactively. Previously every apply hit sudo here and aborted the script
# whenever it could not prompt for a password. Only a first-time install asks.
if [ ! -f /Library/LaunchDaemons/netbird.plist ]; then
    sudo netbird service install
    sudo netbird service start
fi
# netbird up # run this once to login