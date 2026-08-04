---
name: await-agent
description: >-
  Coordinate agent sessions (Claude Code / Codex / Antigravity) across tmux
  windows on the same machine: wait until the agent in another window is done
  before continuing, or send a hand-off message into another agent session.
  Use when the user says things like "when the agent in window 3 is done,
  continue", "wait for the other session to finish", or "when you're done,
  tell the other agent to continue".
---

# Waiting on / notifying another agent session

Every agent tab on this machine broadcasts its state in the `@agent_state`
tmux window option — the same signal that renders the per-tab dot (see
`dot_tmux.conf`). It is set by lifecycle hooks in Claude Code, Codex and
Antigravity alike, so any of them can wait on any other:

| value         | dot      | meaning                                                                      |
| ------------- | -------- | ---------------------------------------------------------------------------- |
| `running`     | blue ●   | working — or its turn ended with background work that will auto-resume it     |
| `needs-input` | red ●    | blocked on the user: permission prompt, plan approval, or turn ended with a question |
| `idle`        | yellow ○ | turn complete, awaiting a prompt — this is "done"                             |
| *(unset)*     | no dot   | no agent has finished a turn in that window, or the session exited            |

Both windows must be on the same tmux server (always true locally, and on each
remote VM). Outside tmux this skill does not apply.

## Identify yourself and the target

```sh
tmux display-message -t "$TMUX_PANE" -p 'me: #{session_name}:#{window_index} (#{window_name})'
tmux list-windows -F '#{window_index}: #{window_name}  state=#{@agent_state}'        # current session
tmux list-windows -a -F '#{session_name}:#{window_index}: #{window_name}  state=#{@agent_state}'  # all sessions
```

Always pass `-t "$TMUX_PANE"` to display-message — without it you get the
window the *user* is currently looking at, not your own. As a target, use
`:3` (window index in your session), `:name`, or `session:3` across sessions.
If the user's reference is ambiguous, `list-windows` usually disambiguates:
the other agent window is the one with `@agent_state` set.

## Wait for another agent (pull)

Check the current state first: `tmux show-option -wqv -t :3 '@agent_state'`

- `running` → start the wait loop below.
- `idle` → it already finished; skip the wait and continue.
- `needs-input` → it is already waiting on the user; tell them, then use the
  second loop below.
- empty → no agent is running there (or it never finished a turn). Re-check
  the target with `list-windows` and confirm with the user before waiting on
  a window that will never signal.

Run the loop as a **background** task so your harness resumes you when it
exits (in Claude Code: Bash with `run_in_background`; if your harness has a
dedicated condition-monitor tool, that works too):

```sh
t=':3'  # target window
while [ "$(tmux show-option -wqv -t "$t" '@agent_state')" = running ]; do sleep 5; done
echo "target now: $(tmux show-option -wqv -t "$t" '@agent_state')"
```

When you are resumed, branch on the landing state:

- `idle` — the agent finished; continue with the follow-up task.
- empty — the session exited. Usually also "done", but say so when reporting.
- `needs-input` — **not done**: it stopped to ask the user something. Report
  that to the user right away, then keep waiting for full completion:

  ```sh
  while s=$(tmux show-option -wqv -t "$t" '@agent_state'); [ "$s" = running ] || [ "$s" = needs-input ]; do sleep 5; done
  ```

If your harness cannot resume on background-task completion, run a bounded
foreground loop instead (here ≤5 min, under typical command timeouts) and
repeat it while the state is still `running`:

```sh
n=0; while [ "$(tmux show-option -wqv -t "$t" '@agent_state')" = running ] && [ "$n" -lt 60 ]; do sleep 5; n=$((n+1)); done; tmux show-option -wqv -t "$t" '@agent_state'
```

## Notify another agent (push)

To message another agent session — typically as *your last action* before
ending your turn, when asked "when you're done, tell window 2 to continue":

```sh
tmux send-keys -t :2 -l 'From window 3 (api-refactor): done — tests pass, schema changes are in db/migrations/. Continue with the backfill.'
sleep 0.3
tmux send-keys -t :2 Enter
```

- `-l` sends the text literally (so nothing in it is interpreted as a key
  name). Send `Enter` separately after a short pause — bundled in the same
  burst it can be swallowed by the TUI's paste detection instead of
  submitting.
- The text lands as that session's next user prompt (queued if it is
  mid-turn), so write it like one: say who you are, what happened, and what
  to do next. The receiver has none of your context — include concrete
  outcomes and paths, not "as discussed".
- **Verify the target window is an agent tab first** (its `@agent_state` is
  set, or the user confirmed it). send-keys types into whatever runs in that
  pane — into a bare shell, your message would execute as a command.

## Choosing a direction

Prefer push when the finishing session can be instructed ("tell window 2 when
done") — no polling at all. Use pull when you cannot instruct the other agent
or it is already mid-task. Don't set up both for the same hand-off: the waiter
would resume twice.
