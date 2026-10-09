---
name: tmux-agent-status
description: Implementation details for the tmux per-tab agent-state dot, note, subagent count, prefix+o overview, and lid-close sleep guard — states, the agent-pty OSC 7501 shim for Claude Code, Codex/pi hooks, and known gotchas. Load when working on dot_tmux.conf, agent-pty/agent-pty.c, the agent-state/agent-note/agent-seen/agent-sleep-guard scripts, or tmux-overview.
---

## Per-tab agent dot + status line (tmux)

A coloured dot per tmux tab shows each agent's state, driven by the `@agent_state`
window option that `window-status-format` reads (`dot_tmux.conf`). It's set by
`~/.local/bin/agent-state`:

| state | dot | meaning |
| --- | --- | --- |
| `needs-input` | red ● | blocked on you: a permission prompt, a plan approval, an MCP elicitation, a turn that died |
| `running` | blue ● | working, or its turn ended with agent-driven work still attached |
| `done` | yellow ● | the turn is over and you have not looked at the tab yet |
| `idle` | yellow ○ | the turn is over and you have looked |
| *(unset)* | no dot | not an agent tab, or the session exited |

Filled means it wants something from you and hollow means it doesn't, which is why
`done` and `idle` share a colour but not a glyph. The four read as one escalation:
red now, yellow-filled when you get a moment, blue nothing, hollow nothing at all.
Everything that ends a turn sets `done`; the only thing that clears it is
`agent-seen`, covered below.

Red is reserved for an **interactive blocker**: something on screen the session
cannot move past until you answer it — a permission prompt, `AskUserQuestion`,
`ExitPlanMode`, an MCP elicitation, or a `StopFailure`. A turn that simply ends
by asking you a question is `done` like every other ending: an unread finished
turn stays filled until the tab has been in front of you, so a closing question
gets collected without a colour of its own. Don't infer red from the reply's
text (a trailing `?`, say) — that needs a punctuation rule in `agents/AGENTS.md`
to prop up the signal, which taxes every agent's writing.

- **Claude Code** reports its own state over the Program Status protocol
  (OSC 7501, [spec](https://superlogical.com/rex/docs/build/program-status)),
  read by the **agent-pty** shim — see "Claude Code: OSC 7501 via agent-pty"
  below. No Claude hooks drive the dot any more.
- **Codex** drives it from lifecycle hooks (`dot_codex/private_hooks.json` →
  `agent-state`): SessionStart → none, UserPromptSubmit/PreToolUse/PostToolUse →
  running, PermissionRequest → needs-input, Stop → done. It has no SessionEnd,
  so the zsh precmd reaper clears the dot when the shell prompt returns. Codex
  0.162 has no OSC 7501 support; when it ships, it can move behind the shim too.
- **Antigravity (`agy`)** has no permission/notification hook event, so the dot
  is driven from its **status line** instead (`dot_gemini/antigravity-cli/executable_statusline.sh`),
  the one payload that exposes `agent_state`, `tool_confirmation_pending` (blocked
  on a tool approval), background tasks AND context % together. That script renders
  the ctx% status line *and* sets `@agent_state` as a side effect. `title.sh` sets
  the window title (inert in tmux — `allow-rename off` — useful outside it). Both
  are wired into `~/.gemini/antigravity-cli/settings.json` by
  `modify_private_settings.json`. agy ≥ 1.0.8 is required (statusline/title/hooks);
  the package script installs latest, older installs need `agy update`.
- **pi** has no shell-out hooks either, but its extension events map cleanly:
  `~/.pi/agent/extensions/agent-dot.ts` (source:
  `private_dot_pi/private_agent/extensions/agent-dot.ts`) runs `agent-state` on
  `session_start` → `none`, `before_agent_start` → `running`, `agent_settled`
  → `done`, `session_shutdown` → `none`. Settled, not `agent_end` — pi may
  auto-retry, auto-compact or drain queued follow-ups after a run ends, and
  only settled means it won't. No red (pi exposes no permission-prompt event)
  and no OSC 7501; the zsh precmd reaper is the backstop for an exit that
  fires nothing, same as for Codex.

A companion `@agent_note` window option carries **what** the agent is doing, since
the dot only says whether it is doing anything — five working agents are five
identical blue dots. Agents set it themselves with `~/.local/bin/agent-note`,
instructed by the "Scratch files and progress" section of `agents/AGENTS.md`; nothing
polls or infers it, so a tab whose agent never calls it just has no note. Only
`tmux-overview` (prefix+o) renders it — the tab bar is deliberately left alone,
being far too narrow for a sentence. `agent-state none` unsets the note alongside
the dot, which is what keeps the two from desyncing: every path that ends a session
(SessionStart, SessionEnd, the zsh precmd reaper) drops the note for free. A new
turn does *not* clear it — the previous note still names the work, and blanking it
would empty the row for exactly as long as the agent takes to write the next one.
`agent-state` also stamps `@agent_since`, the epoch second the state last changed,
which is where the overview's "blocked · 6m12s" comes from; it is written only on
an actual transition, since PostToolUse fires `running` over and over within one
turn and would otherwise keep resetting the clock.

A third window option, `@agent_subagents`, says **how wide** the agent has fanned
out: how many subagents it has in flight. The status bar's agent count reads
`6+11` — six working tabs, eleven subagents between them — and `tmux-overview`
puts the `+11` on the row, in the detail pane and in the session roll-up. Claude
reports each background subagent as an OSC 7501 child record (`id=<agent id>`,
`state=working`, a base64 `title`) and clears it (`state=clear:id=…`) when it
finishes; agent-pty counts the live ones (working or blocked) and sets the
option, unsetting it at zero. The number is Claude-only by construction — Codex
tabs count toward the `6` and can never add to the `+11`.

## done vs idle: the dot remembers whether you looked

"The agent finished" and "you know the agent finished" are different facts, and
only the second one means there is nothing left to do. So a finished turn lands on
`done` (filled ●) and stays there until the tab has actually been in front of you,
at which point `~/.local/bin/agent-seen` opens it to `idle` (hollow ○). With six
agents running, that is the difference between a wall of identical yellow dots and
a list of the two you have not read yet.

"In front of you" is the current window of a client that is both attached and
**focused** — tmux puts `focused` in `#{client_flags}` when `focus-events` is on
and the terminal cooperates. Focus is the whole difficulty: with five sessions in
one terminal, four have a current window nobody is looking at, and marking those
seen would empty the notification before it ever reached you. An absent flag is
ambiguous, though — it means either "not focused now" or "this terminal never
reports focus" — so the server remembers whether it has *ever* seen the flag in
`@agent_focus_reporting`. Until it has, the poll falls back to every attached
client's current window; after that, unfocused means unseen.

Two paths clear it, believable for different reasons. The tmux hooks
(`session-window-changed`, `client-session-changed`, `client-attached`,
`client-focus-in`) hand `agent-seen` the window that just became visible and need
no focus test, because they only fire when you press something. The polling form
runs from `agent-state` the moment it sets `done`, so a tab you are already
watching never flashes, and from `tmux-agent-count` every status tick as the
backstop. Only ever `done` → `idle`: looking at a tab is not answering its
question, so a red dot survives being glanced at.

The attention ladder that `tmux-session-dots` and `tmux-sessionizer` roll a session
up by is `needs-input 4 > done 3 > running 2 > idle 1 > unset 0` — **done outranks
running**, because a finished agent is asking to be collected and a working one is
asking for nothing.

This mirrors herdr's five-state model (blocked / working / done / idle / unknown)
and its ladder, arrived at by reading its source (see "Borrowed from herdr"
below). Two deliberate differences. herdr keeps `done` as a derived state —
detection owns a four-variant enum and the view owns a separate `seen` bool,
because in its architecture those live on different objects with different
lifetimes; we have one option per window, so the pair is precomputed into
`@agent_state` and every consumer tests one value. And herdr's `unknown` turns out
to mean "this pane is a plain shell", which is what an unset `@agent_state`
already means here — the grey `·` in `tmux-overview` is the same thing.

## Claude Code: OSC 7501 via agent-pty

Claude Code ≥ 2.1.295 emits Program Status reports, but **only after the
terminal answers its `OSC 7501 ; ?` probe** (`programStatus` capability, settled
by the startup probe; the only override is `CLAUDE_CODE_DISABLE_TERMINAL_TITLE`,
which turns it *off*). tmux 3.7c neither answers nor forwards the probe, so
inside tmux Claude stays silent. `agent-pty` (`agent-pty/agent-pty.c`, built per
machine by `.chezmoiscripts/run_onchange_after_build-agent-pty.sh.tmpl` into
`~/.local/libexec/agent-pty/claude`) sits between tmux and Claude: it answers the
probe, strips every OSC 7501 sequence from the output, and maps the root record:

| report | `@agent_state` |
| --- | --- |
| `working` | `running` |
| `blocked` (`kind=permission` / `question` / `auth`), `error`, or any child `blocked` | `needs-input` |
| `done` | `done` |
| `idle` | `idle` after a turn; `none` before the first one (startup) |
| `clear` without an id, or the program exits | `none` |

The `claude` shell function in `dot_bash_aliases.tmpl` routes through the shim
when `$TMUX_PANE` is set, stdin and stdout are terminals, and the binary exists;
otherwise it is plain `claude` (no dot). Every launcher (`cc`, `ccw`, `cca`, the
sessionizer's `cc`) goes through that function.

What the reports replaced, each of which was a hook-era workaround:

- **ESC interrupt** fires no hook (anthropics/claude-code#9516) — Claude reports
  `idle` immediately, so `agent-interrupt-state` and its status-line trigger are gone.
- **StopFailure / missed events / stale blue** — the reports are Claude's own
  current state, so the pane-title sweep (`agent-state-sweep`, the `✳`/spinner
  glyphs borrowed from herdr, `@agent_title_spins`, `@agent_sweep_stopped`) is gone.
- **Background work holding the dot** — Claude keeps the root `working` while a
  background subagent runs (verified), and whatever it reports with only
  background shells or monitors attached is taken as-is, so `agent-stop-state`
  and `@agent_bg` are gone.
- **Subagent bookkeeping** — child records replace `agent-subagents` and its
  SubagentStart/Stop/Stop-reconcile set.

Implementation notes worth keeping:

- **tmux calls run in a forked worker**, fed one line per change over a pipe and
  executed in order: never inline (a slow `tmux` would freeze Claude's screen)
  and never in parallel (`working` must not land after `done`; a blocked →
  working → done sequence can take under a second). Changes are de-duplicated,
  so `working` with a fresh `msg` costs nothing.
- **Job control**: forkpty's child leads a new session, whose process group is
  orphaned, and the kernel discards the SIGTSTP Claude sends itself on Ctrl+Z —
  it printed "suspended" and kept running. The shim runs Claude in its own
  foreground group under a small parent inside the pty (as a shell would); when
  Claude stops, that parent SIGSTOPs itself, the outer shim sees it, restores
  the terminal and stops itself, and `fg` resumes the chain.
- **Process name**: the binary is named `claude`, so tmux's
  `pane_current_command` (automatic-rename) and `tmux-pane-close`'s `ps -t` scan
  still see "claude"; Claude itself is on the inner pty, invisible to both.
  macOS `ps -o comm=` prints the full path for it, hence the basename `sed` there.
- **The `msg`** (e.g. "Sleeping 60 seconds", "approve Bash: …") is not used yet;
  `@agent_note` stays agent-authored.

To re-verify after a Claude update, run Claude behind the shim with hooks off
(`--settings '{"disableAllHooks":true}'`) in a scratch tmux session and poll
`#{@agent_state}` / `#{@agent_subagents}` through a permission prompt,
AskUserQuestion, an ESC mid-tool, two background subagents, Ctrl+Z/`fg`, and
exit. Check `strings` on the Claude binary for `OSC 7501` if reports stop: the
probe gating lives next to the XTVERSION probe.

## Borrowed from herdr

The `done` vs `idle` split (finished-and-unseen vs finished-and-seen) and the
attention ladder `blocked > done > working > idle > unknown` came from reading
[herdr](https://github.com/herdrdev/herdr) v0.8.1
(`5203a5dc0f39a082938ea0f9836d6257ea7e155f`, Apache-2.0; no files copied). The
pane-title glyph detection that was also borrowed from there is gone with the
sweep. herdr itself has no OSC 7501 support as of v0.9.3: issue #5069 was closed
under its bugs-only policy and discussion #5073 is open.

## The prefix+o overview, and its two views

`tmux-overview` has a **tree** view (the default) and the original **grid**
montage; **space** switches them and the choice sticks. The tree is one row per
tab under a foldable session header, carrying the dot, the name, the git branch
(peach `⑂ branch` in a linked worktree — the tree keeps the branch there and only
recolours it, where the status bar swaps the branch out for the worktree's
directory name; the tree's detail pane already carries the path), a sapphire `+3` for any subagents that tab has in flight, and a
right-hand detail pane for whatever the cursor is on: full note, worktree path,
time in state, and a live snapshot of that one pane. The `+3` column exists only
while some visible tab has subagents, so the tree gives up no width in the usual
case where nothing is fanned out. **tab**
hides the detail pane, which widens the tree and moves the note onto each row
instead; in the grid it hides the snapshots. **/** narrows to tabs that ever ran
an agent. In the tree `l` unfolds a session or descends into it and `h` ascends
then folds, so `h,h` collapses whatever you are inside of.

Both views open with the cursor on the tab you pressed prefix+o in — you land
where you came from, and ↵ is the way back. Finding that tab needs an explicit
`-t`: a popup inherits no `TMUX_PANE`, and a bare `display-message` with nothing
to resolve against answers for the server's most recently active session, which
is only sometimes the one you are sitting in. What it does inherit is `TMUX`,
whose third field is the id of the session the popup was displayed for, and a
session has exactly one current window — the tab. A folded session, or one the
`/` filter emptied of that tab, gets its header row instead. Each view places
the cursor once, on its first frame, so moving away from it sticks.

State lives in tmux options rather than a dotfile of ours — `@overview_view`,
`@overview_detail`, `@overview_panes` and `@overview_agents` on the server, plus
`@overview_fold` per session. Two things keep it cheap: the tree captures only the
one pane its detail column shows (the grid captures every window, every tick), and
branch lookups are cached per directory for a few seconds, since a branch moves far
more slowly than the 1s redraw.

## Lid-close sleep guard (macOS)

`@agent_state` has a second consumer: `~/.local/bin/agent-sleep-guard` keeps the
Mac awake through a **lid close** while any window is `running`, then lets it
sleep once the last one finishes. Closing the lid is a forced sleep, so the
`caffeinate -i` that Claude Code spawns while it works — which is enough for
idle sleep — doesn't survive it; the only knob that does is pmset's undocumented
`disablesleep`, which needs root. Three moving parts:

- `run_onchange_setup-agent-sleep-guard_darwin.sh.tmpl` installs the root half:
  `/etc/sudoers.d/agent-sleep-guard` (NOPASSWD for exactly
  `pmset -a disablesleep 0|1`, nothing more) and a boot-reset LaunchDaemon.
- `com.timvink.agent-sleep-guard` LaunchAgent ticks the guard every 30s. It
  polls rather than reacting to the lid because the hold must already be set
  when the lid shuts — there's no usable lid-close hook.
- A 5-minute grace buffer (`GRACE_MIN`): when the LAST running agent finishes,
  the hold stays up for five more minutes before releasing. Agents work in
  short turns with idle gaps between them, and releasing the instant the count
  hits 0 meant closing the lid during a one-minute gap slept the Mac out from
  under work that resumed seconds later. Grace time counts toward the cap, and
  the cap's latch is only cleared once the quiet has outlasted the buffer —
  otherwise a capped batch could sneak straight back into a hold.
- Guards against a stuck hold cooking the laptop in a bag: a 90-minute cap
  (battery only — on AC there is no cap, plugging in clears the latch, and the
  clock restarts on unplug) that latches off until the running count hits 0 and
  stays there past the grace buffer, a 30% battery floor (enforced mid-grace too), and the boot-reset
  daemon for the case where the guard dies mid-hold.

Only `running` counts — a red `needs-input` agent will never finish unattended.
Log: `~/Library/Logs/agent-sleep-guard.log`, written on transitions only.
