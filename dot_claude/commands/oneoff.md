---
description: Do a trusted one-off task, then exit Claude and the shell when it's verified done
argument-hint: <task to finish autonomously>
---
Task: $ARGUMENTS

Carry this out and finish without reporting back — the clean exit is the only
signal needed that it worked. Use the `close-yourself` skill: verify the work
before exiting, stop and ask instead of exiting if you're blocked, and call
`~/.local/bin/agent-exit` as your final action once success is verified.
