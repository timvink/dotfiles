#!/bin/sh
# chezmoi modify_ script for ~/.config/hypr/looknfeel.lua (Omarchy only).
# Omarchy owns this file (it ships it and its migrations may edit it), so keep
# whatever is there and only append my block between the markers below,
# replacing an earlier copy of it.
sed '/^-- BEGIN chezmoi/,/^-- END chezmoi/d'
cat <<'LUA'
-- BEGIN chezmoi (dot_config/hypr/modify_looknfeel.lua; edit there)
-- Instant focus changes: Omarchy animates the border's colour gradient when
-- focus moves, which makes Alt+Tab feel slow. Window open/close and the
-- other animations stay.
hl.animation({ leaf = "border", enabled = false })
-- END chezmoi
LUA
