---
name: await-agent
description: Wait for another agent session in tmux or send it an explicitly requested handoff message. Both sessions must use the same tmux server.
---

# Coordinate tmux agent sessions

Identify your own pane explicitly; an untargeted query may report the window the
user is viewing instead:

```sh
tmux display-message -t "$TMUX_PANE" -p '#{session_name}:#{window_index}'
tmux list-windows -a -F '#{session_name}:#{window_index} #{window_id} #{window_name} state=#{@agent_state}'
```

Resolve the user's target from the listing, then prefer its stable window ID
(such as `@12`) for subsequent calls. Outside tmux, this workflow is unavailable.

## Wait

Read the target's state with `tmux show-option -wqv -t @12 '@agent_state'`:

| State | Action |
| --- | --- |
| `running` | Wait; the agent may also have automatic follow-up work |
| `done` or `idle` | Continue; both mean the turn finished |
| `needs-input` | Tell the user the other agent needs input; keep waiting if requested |
| Empty or missing window | Check whether the agent exited or the target was wrong |

Prefer a background wait that the harness can resume. Otherwise use bounded
polls so this session can report progress and receive input:

```sh
target='@12'
n=0
while [ "$n" -lt 6 ]; do
    state=$(tmux show-option -wqv -t "$target" '@agent_state') || break
    case "$state" in running|needs-input) ;; *) break ;; esac
    sleep 5
    n=$((n + 1))
done
tmux show-option -wqv -t "$target" '@agent_state'
```

Inspect the landing state before continuing. A permission prompt is not completion.
An empty state alone is not proof of success; verify the target or report its exit.

## Send a requested handoff

Verify the target pane hosts the intended agent. `send-keys` also types into bare
shells, where prose could execute as a command. Include your identity, concrete
outcome, relevant paths, and the next action; the recipient lacks your context.

```sh
tmux send-keys -t @12 -l 'From API session: tests pass; migration is ready in db/migrations/. Continue with the backfill.'
sleep 0.3
tmux send-keys -t @12 Enter
```

Send text literally with `-l`, then Enter separately so paste detection doesn't
swallow submission. The message becomes that session's next prompt. Send only
when the user requested the handoff. Prefer notification over polling when the
finishing agent can be instructed; avoid setting up both for one handoff.
