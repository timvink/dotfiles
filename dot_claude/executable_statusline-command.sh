#!/usr/bin/env bash
# Claude Code status line — Catppuccin Mocha, Starship-style.
# Wired via .statusLine in settings.json (injected by modify_settings.json).
# Claude pipes a JSON blob on stdin and renders our stdout (ANSI truecolor ok).
#
# Layout:  dim/path    branch    [model]    ctx:NN%
#   path   — overlay0, ~ for $HOME
#   branch — green with a powerline  glyph; short SHA when detached, blank
#            outside a repo. GIT_OPTIONAL_LOCKS=0 so a busy index never blocks.
#   model  — blue, in dim brackets
#   ctx    — colour-coded by fill: green <50%, yellow <80%, red beyond

input=$(cat)
cwd=$(echo "$input"   | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
used=$(echo "$input"  | jq -r '.context_window.used_percentage // empty')

short_cwd="${cwd/#$HOME/~}"

branch=""
if b=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null); then
    branch="$b"
elif b=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" rev-parse --short HEAD 2>/dev/null); then
    branch="$b"
fi

R=$'\033[0m'                       # reset
DIM=$'\033[38;2;108;112;134m'      # overlay0  #6c7086
GREEN=$'\033[38;2;166;227;161m'    # green     #a6e3a1
BLUE=$'\033[38;2;137;180;250m'     # blue      #89b4fa
YEL=$'\033[38;2;249;226;175m'      # yellow    #f9e2af
RED=$'\033[38;2;243;139;168m'      # red       #f38ba8

out="${DIM}${short_cwd}${R}"
[ -n "$branch" ] && out+="  ${GREEN} ${branch}${R}"
[ -n "$model" ]  && out+="  ${DIM}[${BLUE}${model}${DIM}]${R}"
if [ -n "$used" ]; then
    i=${used%.*}
    c=$GREEN; [ "$i" -ge 50 ] && c=$YEL; [ "$i" -ge 80 ] && c=$RED
    out+="  ${c}ctx:${i}%${R}"
fi

printf '%s\n' "$out"
