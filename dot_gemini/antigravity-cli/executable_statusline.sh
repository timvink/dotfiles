#!/usr/bin/env bash
# Antigravity CLI (agy) status line — Catppuccin Mocha, mirroring my Claude Code
# and Codex status lines (dir · branch · model · ctx%) for cross-tool consistency.
# Wired via .statusLine in ~/.gemini/antigravity-cli/settings.json (injected by
# dot_gemini/antigravity-cli/modify_settings.json).
#
# agy runs this on every agent-state change, pipes a JSON state payload (snake_case)
# on stdin, and renders our stdout (ANSI truecolor ok) in the TUI status line.
#
# It ALSO drives the per-tab tmux dot — the same @agent_state signal used for
# Claude/Codex (see ~/.local/bin/agent-state) — as a side effect. The status-line
# payload is the ONLY place agy exposes everything the dot needs in one shot:
# agent_state, tool_confirmation_pending (a tool-approval dialog is up → blocked on
# you), the background-task count, the context %, AND it fires on the transition to
# idle. agy's hook events (PreToolUse/PreInvocation/Stop/…) have NO permission or
# notification event, so a hook-driven dot like Claude/Codex use literally can't
# see the "blocked on a confirmation" case — the status line can. One mechanism,
# both outputs.
#
#   tool_confirmation_pending      → needs-input red ●  (blocked on a tool approval)
#   agent_state thinking/working/
#     tool_use                     → running blue ●      (agent is working)
#   idle + a background task runs   → running blue ●      (the task will resume it)
#   idle + nothing produced yet    → none (no dot)       (fresh session, or a reused
#                                                         tmux window's stale dot cleared)
#   idle + final line ends with ?  → needs-input red ●   (turn ended asking you
#                                                         something — the end-of-turn
#                                                         signal; see ~/.claude/CLAUDE.md)
#   idle otherwise                 → idle yellow ○        (turn done — your turn)
#
# The dot side-effect is a no-op outside tmux (agent-state handles that). Any jq
# failure falls through to a clean state, so a finished tab is never wrongly stuck
# red and agy never renders a blank status line.

input=$(cat)

# One jq pass for the fields we need (payload is snake_case). One value per line,
# read with mapfile so empty fields (e.g. no branch / no model) are preserved
# positionally — `read` with a whitespace IFS would collapse them and misalign.
mapfile -t F < <(printf '%s' "$input" | jq -r '
    (.agent_state // "idle"),
    (.context_window.used_percentage // 0),
    (.vcs.branch // ""),
    (.vcs.dirty // false),
    (.model.display_name // ""),
    (.workspace.current_dir // .cwd // ""),
    (.tool_confirmation_pending // false),
    (.task_count // (.background_tasks | length) // 0),
    (.context_window.total_output_tokens // 0),
    (.conversation_id // "")
  ' 2>/dev/null)

state=${F[0]:-idle}
used=${F[1]:-0}
branch=${F[2]-}
dirty=${F[3]:-false}
model=${F[4]-}
cwd=${F[5]-}
confirm=${F[6]:-false}
tasks=${F[7]:-0}
out_tokens=${F[8]:-0}
conv=${F[9]-}

# ── drive the tmux dot ───────────────────────────────────────────────────────
set_dot() { "$HOME/.local/bin/agent-state" "$1" 2>/dev/null || true; }

if [ "$confirm" = true ]; then
    set_dot needs-input
else
    case "$state" in
        thinking|working|tool_use)
            set_dot running ;;
        *)
            if [ "${tasks:-0}" -gt 0 ] 2>/dev/null; then
                set_dot running                       # background work will resume it
            elif [ "${out_tokens:-0}" -eq 0 ] 2>/dev/null; then
                set_dot none                          # fresh / nothing produced yet
            else
                # Idle with output: red if the final assistant line ends with "?",
                # else "your turn". The final message is the last MODEL planner
                # response in the documented transcript path; any failure leaves us
                # at idle (never wrongly stuck red).
                last=""
                tp="$HOME/.gemini/antigravity-cli/brain/$conv/.system_generated/logs/transcript.jsonl"
                if [ -n "$conv" ] && [ -f "$tp" ]; then
                    last=$(jq -rc 'select(.type == "PLANNER_RESPONSE" and .source == "MODEL") | .content' "$tp" 2>/dev/null \
                        | tail -1 | awk 'NF {l = $0} END {print l}' | sed 's/[[:space:]]*$//')
                fi
                case "$last" in
                    *\?) set_dot needs-input ;;
                    *)   set_dot idle ;;
                esac
            fi
            ;;
    esac
fi

# ── render the status line ───────────────────────────────────────────────────
short_cwd="${cwd/#$HOME/~}"

R=$'\033[0m'                       # reset
DIM=$'\033[38;2;108;112;134m'      # overlay0  #6c7086
GREEN=$'\033[38;2;166;227;161m'    # green     #a6e3a1
BLUE=$'\033[38;2;137;180;250m'     # blue      #89b4fa
YEL=$'\033[38;2;249;226;175m'      # yellow    #f9e2af
RED=$'\033[38;2;243;139;168m'      # red       #f38ba8

out="${DIM}${short_cwd}${R}"
if [ -n "$branch" ]; then
    if [ "$dirty" = true ]; then
        out+="  ${GREEN} ${branch}${YEL}*${R}"
    else
        out+="  ${GREEN} ${branch}${R}"
    fi
fi
[ -n "$model" ] && out+="  ${DIM}[${BLUE}${model}${DIM}]${R}"
if [ -n "$used" ]; then
    i=${used%.*}; i=${i:-0}
    c=$GREEN; [ "$i" -ge 50 ] 2>/dev/null && c=$YEL; [ "$i" -ge 80 ] 2>/dev/null && c=$RED
    out+="  ${c}ctx:${i}%${R}"
fi

printf '%s\n' "$out"
