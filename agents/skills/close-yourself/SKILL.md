---
name: close-yourself
description: End this agent session and its terminal tab or tmux pane when the user asks to close yourself, optionally after completing a task.
---

# Close this session

When the user asks to close the session, use the local helper as the final action:

```sh
~/.local/bin/agent-exit
```

It closes the agent and its host shell/tab, or kills the pane under tmux. Nothing
can run afterward, so verify the requested work and report necessary information
before calling it. If a blocker needs the user's decision, keep the session open
and ask instead.

- “Close yourself when done” or “do X, then close yourself”: finish and verify,
  report anything material, then exit. No additional sign-off is needed.
- “Close yourself unless there's something important I should know”: exit silently
  only if nothing material needs attention. Otherwise report it and leave the
  session open for a response.

In pi, prefer its native `/exit` when the interface can invoke it. The helper
returns zero even when it cannot identify the agent process; don't treat that
exit status as proof that the terminal closed.
