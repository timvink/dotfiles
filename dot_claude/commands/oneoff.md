---
description: Do a trusted one-off task, then exit Claude and the shell when it's verified done
argument-hint: <task to finish autonomously>
---
Task: $ARGUMENTS

You are trusted to carry this out and finish without reporting back — the clean
exit is the only signal needed that it worked. Follow these rules:

1. Define explicit success criteria up front, do the work, and **verify** it
   (run it, read it back, check the output) before you consider it finished.
   Don't claim done on a hunch.

2. If you hit a genuine decision only the user can make — or verification fails
   and you can't fix it yourself — **stop and ask**. Do not exit. End the turn
   normally so the user sees your question.

3. If — and only if — success is verified, run this as your final action, with
   no summary or sign-off:

   ```
   ~/.local/bin/agent-exit
   ```

   It closes Claude and the terminal tab in one shot (kill-pane under tmux,
   otherwise it signals Claude and the host shell). Nothing runs after it, so
   make sure every check has passed before you call it.
