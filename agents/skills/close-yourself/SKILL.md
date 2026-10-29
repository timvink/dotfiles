---
name: close-yourself
description: End this agent session and its terminal tab or tmux pane when the user asks to close yourself, optionally after completing a task.
---

# Close this session

Finish and verify any requested work, then report anything material before the
closing action. If a blocker needs the user's decision, keep the session open.

Choose the closing action from the capabilities available in this session:

- **tmux terminal with shell tools under a shared server:** identify this
  session's pane using `tmux list-panes -a` with pane ids and working directories.
  Confirm a candidate with `tmux capture-pane -p -t PANE_ID -S -80`: its visible
  conversation must match this session's recent user request and response.
  A matching working directory alone is not enough. Once confirmed, use
  `tmux kill-pane -t PANE_ID` as the final action. This closes the terminal pane
  even though tool execution is outside its process tree.
- **pi:** prefer its native `/exit` when the interface can invoke it.
- **Terminal agent without a native closing tool:** use the local helper as the
  final action, provided shell commands run inside this agent's process tree:

```sh
~/.local/bin/agent-exit
```

The helper closes the agent and its host shell/tab, or kills the pane under tmux.
It is not suitable for shell tools running under a shared `codex app-server`:
their ancestry belongs to the server, and inherited `TMUX_PANE` can be stale or
refer to another session. Never kill the shared server or select a pane based
only on that inherited variable. If a terminal pane cannot be identified
reliably, report the limitation instead of closing a guessed target.

`mcp__codex_tui__set_thread_archived` with `{"archived": true}` and no `threadId`
archives the calling task and its descendants. It does **not** exit the terminal
client or close its pane, so it does not fulfill a request to close yourself in
a terminal. Use it only when archiving the task is the requested outcome.

- “Close yourself when done” or “do X, then close yourself”: finish and verify,
  report anything material, then exit. No additional sign-off is needed.
- “Close yourself unless there's something important I should know”: exit silently
  only if nothing material needs attention. Otherwise report it and leave the
  session open for a response.

The helper returns zero even when it cannot identify the agent process; don't
treat that exit status as proof that the terminal closed. After a successful
closing action, do not send another sign-off or run more tools.
