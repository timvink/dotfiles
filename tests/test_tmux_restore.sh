#!/usr/bin/env bash
# Real tmux regression checks, isolated from the user's server and conversations.
set -euo pipefail

source_dir=$(cd "$(dirname "$0")/.." && pwd)
test_dir=$(mktemp -d /tmp/tmux-agent-restore.XXXXXX)
tmux_bin=$(command -v tmux)
socket="$test_dir/tmux.sock"
cleanup() {
    "$tmux_bin" -S "$socket" kill-server 2>/dev/null || true
    rm -rf "$test_dir"
}
trap cleanup EXIT
export HOME="$test_dir/home"
export TMUX="$socket,0,0"
mkdir -p "$HOME/.tmux/resurrect" "$test_dir/work dir" "$test_dir/bin"
# Force every tmux call, including those made by the restore script, to our server.
printf '#!/bin/sh\nexec %q -S %q "$@"\n' "$tmux_bin" "$socket" > "$test_dir/bin/tmux"
chmod +x "$test_dir/bin/tmux"
export PATH="$test_dir/bin:$PATH"
cat > "$HOME/.bashrc" <<'EOF'
# Deliberately slow startup: input sent before readline starts can be discarded.
sleep 1
claude() { printf 'claude:%s:%s\n' "$PWD" "$*" >> "$HOME/resumed"; sleep 60; }
codex() { printf 'codex:%s:%s\n' "$PWD" "$*" >> "$HOME/resumed"; sleep 60; }
EOF
restore="$source_dir/dot_local/bin/executable_tmux-claude-sessions"
tmux -f /dev/null new-session -d -s restore /bin/bash
tmux set-option -g default-shell /bin/bash
tmux set-option -g renumber-windows on
tmux new-window -d -t restore:3 'printf "SAVED_PANE_SCREEN\n"; exec /bin/bash'
tmux new-window -d -t restore:4 /bin/bash
tmux new-window -d -t restore:5 'exec sleep 60'
printf 'restore:3.0\t%s\tclaude-id\n' "$test_dir/work dir" > "$HOME/.tmux/resurrect/claude-sessions.tsv"
printf 'restore:4.0\t%s\tcodex-id\nrestore:5.0\t%s\tdo-not-replace\n' \
    "$test_dir/work dir" "$test_dir/work dir" > "$HOME/.tmux/resurrect/codex-sessions.tsv"
live_pid=$(tmux display-message -p -t restore:5.0 '#{pane_pid}')
bash "$restore" before-restore
test "$(tmux show-option -gv renumber-windows)" = off
# Temporary windows must not renumber the saved conversation targets.
tmux kill-window -t restore:0
test "$(tmux display-message -p -t restore:4.0 '#{window_index}')" = 4
bash "$restore" restore
test "$(tmux show-option -gv renumber-windows)" = on
for ((attempt=0; attempt<50; attempt++)); do
    if [ -f "$HOME/resumed" ] && [ "$(wc -l < "$HOME/resumed")" -eq 2 ]; then break; fi
    sleep 0.1
done
test "$(wc -l < "$HOME/resumed")" -eq 2
tmux capture-pane -p -S - -t restore:3.0 | rg -Fx SAVED_PANE_SCREEN
rg -Fx "claude:$test_dir/work dir:--resume claude-id" "$HOME/resumed"
rg -Fx "codex:$test_dir/work dir:resume codex-id" "$HOME/resumed"
test "$(tmux display-message -p -t restore:5.0 '#{pane_pid}')" = "$live_pid"
# Repeated manual restores must leave foreground agents/programs alone.
bash "$restore" restore
test "$(wc -l < "$HOME/resumed")" -eq 2
printf 'tmux agent restore checks passed\n'
