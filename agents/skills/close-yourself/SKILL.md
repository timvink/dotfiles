---
name: close-yourself
description: End this agent session and its terminal tab or tmux pane when the user asks to close yourself, optionally after completing a task.
---

# Close this session

Finish and verify any requested work, then report anything material before the
closing action. If a blocker needs the user's decision, keep the session open.

Choose the closing action from the capabilities available in this session:

- **Codex with task tools:** call `mcp__codex_tui__set_thread_archived` with
  `{"archived": true}` as the final action. Omit `threadId` to target the calling
  task. This archives the current task and its descendants; it does not terminate
  the shared server or close unrelated tasks or terminal panes.
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
only on that inherited variable. If no native closing tool is available there,
report the limitation instead of claiming the session closed.

- “Close yourself when done” or “do X, then close yourself”: finish and verify,
  report anything material, then exit. No additional sign-off is needed.
- “Close yourself unless there's something important I should know”: exit silently
  only if nothing material needs attention. Otherwise report it and leave the
  session open for a response.

The helper returns zero even when it cannot identify the agent process; don't
treat that exit status as proof that the terminal closed. After a successful
native closing action, do not send another sign-off or run more tools.
