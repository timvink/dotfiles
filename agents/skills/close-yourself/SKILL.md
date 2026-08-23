---
name: close-yourself
description: >
  How an agent ends its own session — exits the agent process and closes the
  terminal tab or tmux pane hosting it. Use when the user asks the agent to
  "close yourself", "close yourself when done", "close yourself unless there's
  something important I should know", or otherwise end its own session after
  finishing work. Works in Claude Code, Codex, Antigravity and pi.
---

# Close yourself

You have no built-in "exit yourself" tool in most agents, so ending your session
means running one script as your **final action**:

```
~/.local/bin/agent-exit
```

It closes you and the shell/tab hosting you in one shot (`tmux kill-pane` under
tmux; otherwise it signals the agent process and the host shell). Nothing runs
after it — no summary, no sign-off, no trailing text. Make sure everything below
is settled before you call it.

## Before you exit

1. **Verify your work is done.** Run it, read it back, check the output. Don't
   claim done on a hunch.
2. **Say anything important first.** If there's something the user must know —
   a decision you made, a warning, a failed check, a surprising result — write
   it in your final message, then call `agent-exit`. Once the script runs,
   nothing else gets through.
3. **If you're blocked, don't exit.** A genuine decision only the user can make,
   or verification you can't fix yourself, means you stop and ask instead.
   End the turn normally so they see your question. Exit only once resolved.

## Variants of the request

- *"Close yourself when done"* — finish, verify, exit silently.
- *"Close yourself unless there's something important I should know"* — if
  nothing important surfaced, exit silently. If something did, report it and
  end the turn normally so the user can respond; do not exit.
- *"Do X, then close yourself"* — treat as done-then-exit, with X verified
  before exiting.

## Notes per tool

- **pi** has a native `/exit` command that does the same thing; prefer it there.
- The script always exits 0. If it finds no agent process to signal (e.g. an
  unexpected host), it silently leaves the session running — safe to call.
