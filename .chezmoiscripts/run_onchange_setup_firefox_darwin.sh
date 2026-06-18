#!/bin/sh
# Firefox user.js settings
# Source: https://joshua.hu/firefox-making-right-click-not-suck

FIREFOX_PROFILES_DIR="$HOME/Library/Application Support/Firefox/Profiles"

if [ ! -d "$FIREFOX_PROFILES_DIR" ]; then
    echo "Firefox profiles directory not found, skipping Firefox setup."
    exit 0
fi

USER_JS_CONTENT='// Firefox right-click menu cleanup
// Source: https://joshua.hu/firefox-making-right-click-not-suck

// Remove "Translate Selection" button
user_pref("browser.translations.select.enable", false);

// Remove "Take Screenshot" button (disables built-in screenshot tool)
user_pref("screenshots.browser.component.enabled", false);

// Remove "Copy Link to Highlight" button (disables Text Fragments)
user_pref("dom.text_fragments.enabled", false);

// Remove "Copy Clean Link" / "Copy Link Without Site Tracking" buttons
user_pref("privacy.query_stripping.strip_on_share.enabled", false);

// Remove "Inspect Accessibility Properties" button (disables DevTools Accessibility Inspector)
user_pref("devtools.accessibility.enabled", false);

// Remove "Ask an AI Chatbot" button
user_pref("browser.ml.chat.menu", false);

// Disable Link Previews and AI-generated key points
user_pref("browser.ml.linkPreview.enabled", false);

// Remove "Copy Text From Image" button (disables OCR on images)
user_pref("dom.text-recognition.enabled", false);

// Disable Visual Search (Google Lens integration)
user_pref("browser.search.visualSearch.featureGate", false);

// Disable address autofill and its menu entry
user_pref("extensions.formautofill.addresses.enabled", false);

// Disable credit card/payment method autofill
user_pref("extensions.formautofill.creditCards.enabled", false);

// Use Firefox own context menus instead of native macOS ones
user_pref("widget.macos.native-context-menus", false);

// Disable built-in password manager (using external password manager instead)
user_pref("signon.rememberSignons", false);
user_pref("signon.autofillForms", false);
'

# Route my headless dev boxes (devbox / homelab) through their per-box SSH SOCKS
# proxy, so http://devbox:<port> loads here. socks_remote_dns is essential: the
# *box* resolves the hostname to its own loopback. The PAC and the proxy ports
# live in ~/.config/proxy.pac and the devbox alias / homelab ssh config.
# Built separately (double-quoted) so $HOME expands into the file:// URL.
PROXY_PREFS="
// --- dev box SOCKS routing (managed by chezmoi) ---
user_pref(\"network.proxy.type\", 2);
user_pref(\"network.proxy.autoconfig_url\", \"file://$HOME/.config/proxy.pac\");
user_pref(\"network.proxy.socks_remote_dns\", true);
"

# Deploy user.js to all default-release profiles
for profile_dir in "$FIREFOX_PROFILES_DIR"/*.default-release; do
    if [ -d "$profile_dir" ]; then
        echo "Writing Firefox user.js to: $profile_dir"
        printf '%s%s' "$USER_JS_CONTENT" "$PROXY_PREFS" > "$profile_dir/user.js"
    fi
done
