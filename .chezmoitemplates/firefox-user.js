// Firefox right-click menu cleanup
// Source: https://joshua.hu/firefox-making-right-click-not-suck

// Remove "Translate Selection" button
user_pref("browser.translations.select.enable", false);

// Keep the built-in screenshot tool (Cmd+Option+Shift+P, full-page capture).
// Explicitly true, not just omitted: an earlier false persists in prefs.js.
user_pref("screenshots.browser.component.enabled", true);

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

// Disable built-in password manager (using external password manager instead)
user_pref("signon.rememberSignons", false);
user_pref("signon.autofillForms", false);
