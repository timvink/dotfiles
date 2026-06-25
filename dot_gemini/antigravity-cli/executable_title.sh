#!/usr/bin/env bash
# Antigravity CLI (agy) terminal window title. Wired via .title in
# ~/.gemini/antigravity-cli/settings.json (injected by modify_settings.json). agy
# pipes the same JSON state payload as the status line on stdin and uses our
# stdout (non-printables / ANSI stripped) as the terminal window title.
#
# Inside tmux this is intentionally inert: tmux owns titles (set-titles-string),
# per-tab state shows as the @agent_state dot, and `allow-rename off` (dot_tmux.conf)
# stops apps from clobbering window names. Outside tmux (a bare Ghostty tab) it
# gives the terminal a live "<state> · <workspace>" title, so a minimised or
# unfocused agy is still legible at a glance.

input=$(cat)
IFS=$'\t' read -r state cwd <<<"$(
  printf '%s' "$input" | jq -r '[(.agent_state // "idle"), (.workspace.current_dir // .cwd // "")] | @tsv' 2>/dev/null
)"

ws=$(basename "$cwd" 2>/dev/null)
[ -z "$ws" ] && ws="agy"

case "$state" in
    initializing) emoji="🚀" ;;
    idle)         emoji="😴" ;;
    thinking)     emoji="🤔" ;;
    working)      emoji="🏃" ;;
    tool_use)     emoji="🛠️" ;;
    *)            emoji="🤖" ;;
esac

printf '%s %s · %s\n' "$emoji" "$state" "$ws"
