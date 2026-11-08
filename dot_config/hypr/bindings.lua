-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- Dictation keys from before Alt + Space and Right Alt became the defaults.
-- Remove these lines to give the keys back to applications.
if o.dictation_installed and o.dictation_installed() then
  o.bind("SUPER + CTRL + X", "Toggle dictation", "omarchy-dictation toggle")
  o.bind_hold("F9", "Start dictation (push-to-talk)", "omarchy-dictation start", "Stop dictation (push-to-talk)", "omarchy-dictation stop")
end

-- Hyper app launcher, same keys as Karabiner on the Mac (README.md). Hyper is
-- Ctrl+Alt+Super+Shift: Caps hold via keyd, a thumb hold on the Voyager.
-- Omarchy binds no four-modifier combo. All keys are left-hand so the right
-- hand stays on the mouse. Each key focuses the app's window if one is open,
-- wherever it is, and launches the app otherwise. Patterns are anchored to the
-- window class so a terminal titled "nvim firefox-user.js" doesn't match.
local hyper = "CTRL + ALT + SUPER + SHIFT + "
o.bind(hyper .. "F", "Firefox", { launch = "firefox", focus = "^firefox$" })
o.bind(hyper .. "D", "Terminal", { launch = "ghostty", focus = "^com\\.mitchellh\\.ghostty$" })
o.bind(hyper .. "R", "Obsidian", { launch = "obsidian", focus = "^obsidian$" })
o.bind(hyper .. "E", "Files", { launch = "nautilus --new-window", focus = "^org\\.gnome\\.Nautilus$" })
-- Not { omarchy = "spotify" }: its unanchored pattern also matches a Firefox
-- window whose title mentions Spotify. The setup script installs it.
o.bind(hyper .. "A", "Spotify", { launch = "spotify", focus = "^Spotify$" })
-- TodoTim is an Omarchy shell plugin (installed by .chezmoiscripts), so Hyper+T
-- toggles its panel instead of focusing a window.
o.bind(hyper .. "T", "TodoTim", { panel = "timvink.todotim" })

-- Hyper+W: Signal, or WhatsApp when Signal is already focused, so a second
-- press toggles between the two. Signal installs itself on first launch.
local whatsapp = o.launch_webapp_sole("WhatsApp", "https://web.whatsapp.com/")
o.bind(hyper .. "W", "Signal / WhatsApp", function()
  local window = hl.get_active_window()
  if window and window.class and window.class:lower():find("signal") then
    hl.exec_cmd(whatsapp)
  else
    hl.exec_cmd("omarchy-launch-signal")
  end
end)

-- Hybrid workspaces: apps I glance at and leave get a workspace of their own;
-- everything else (Firefox, Ghostty) shares the current one. The Hyper key
-- jumps there because focusing a window switches to its workspace. Window
-- rules apply when a window opens, so an already-open window stays put.
o.window("^obsidian$", { workspace = "7" })
o.window("^signal$", { workspace = "8" })
o.window("^chrome-web\\.whatsapp\\.com__.*$", { workspace = "8" })
o.window("^Spotify$", { workspace = "9" })

-- Alt+Tab: back to the previously focused window, on any workspace, like a
-- single Cmd-Tab tap on the Mac; pressing again flips back. Omarchy's default
-- cycles only the current workspace, which dedicated workspaces would defeat.
-- One step of history only; Super+Tab still walks workspaces.
hl.unbind("ALT + TAB")
hl.unbind("ALT + SHIFT + TAB")
o.bind("ALT + TAB", "Previous window", hl.dsp.focus({ last = true }))
