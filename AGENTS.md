# Working in this dotfiles repo

Chezmoi-managed dotfiles. Single developer, work directly on `main`, no PR
workflow. macOS is primary; everything that lands here should also work on
Linux (used on remote VMs over SSH).

## Design principle: alt+hjkl across all my tools

Navigation uses `alt` + vim-direction keys in tmux (terminal, local and
remote) and VSCode — intentionally identical so muscle memory carries
between them. When adding a new binding anywhere, prefer `alt+<vim-key>` if
it fits the cross-tool model. Specific bindings and their rationale are
documented next to the configs that set them.

## chezmoi conventions

- **Apps that mutate their own config at runtime** (Claude Code's
  `settings.json`, Codex's `config.toml`, etc.) use `modify_` chezmoi
  scripts that inject only our managed keys/lines and preserve runtime
  state (project trust levels, plugins, marketplace caches). Don't fully
  manage these files — `chezmoi apply` would clobber runtime additions.
- `chezmoi apply --force` is fine when an installer (Antigravity, …)
  has appended a line to a managed file; the source is authoritative.
- Linux package script: `run_onchange_setup_packages_linux.sh` at repo
  root. macOS: `.chezmoiscripts/run_onchange_setup_packages_darwin.sh`.

## Shared agent config (Claude + Codex + Antigravity)

Cross-tool agent config lives in ONE place at the repo root: `agents/`, holding
`AGENTS.md` (shared global instructions) and `skills/` (shared Agent Skills).
Everything there is symlinked into each tool, since each only scans its own
paths and none has a config knob for an extra search path:

- `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md` and `~/.gemini/GEMINI.md`
  (Antigravity / agy) → `agents/AGENTS.md`, via `dot_claude/symlink_CLAUDE.md.tmpl`,
  `dot_codex/symlink_AGENTS.md.tmpl` and `dot_gemini/symlink_GEMINI.md.tmpl`
  (Claude doesn't read AGENTS.md natively, so its CLAUDE.md is the symlink; same
  for Gemini's GEMINI.md). One instruction file, all three tools.
- `~/.claude/skills/*`, `~/.codex/skills/*` and `~/.gemini/config/skills/*`
  (Antigravity's global skills dir) → `agents/skills/*`, via
  `run_onchange_after_link-agents-skills.sh.tmpl`.

Symlinks point straight at the repo, so an edit is instantly live in every tool —
no applied copy. `agents/` is `.chezmoiignore`d so chezmoi doesn't also copy it
to `~/agents`. Rules that both tools must follow go in `agents/AGENTS.md` (Codex's
only prose channel); Claude-only/path-scoped rules go in `dot_claude/rules/`. Codex
has no prose-rules dir — its `~/.codex/rules/` is command-approval (Starlark), not
instructions. Full rationale and the add/remove/private-skill workflow are in
`agents/README.md`.

## Per-tab agent dot + status line (tmux)

A coloured dot per tmux tab shows each agent's state, driven by the `@agent_state`
window option that `window-status-format` reads (`dot_tmux.conf`). It's set by
`~/.local/bin/agent-state`:

| state | dot | meaning |
| --- | --- | --- |
| `needs-input` | red ● | blocked on you: a permission prompt, a plan approval, or a turn that ended with a question |
| `running` | blue ● | working, or its turn ended with agent-driven work still attached |
| `done` | yellow ● | the turn is over and you have not looked at the tab yet |
| `idle` | yellow ○ | the turn is over and you have looked |
| *(unset)* | no dot | not an agent tab, or the session exited |

Filled means it wants something from you and hollow means it doesn't, which is why
`done` and `idle` share a colour but not a glyph. The four read as one escalation:
red now, yellow-filled when you get a moment, blue nothing, hollow nothing at all.
Everything that ends a turn sets `done`; the only thing that clears it is
`agent-seen`, covered below.

- **Claude Code / Codex** drive it from lifecycle hooks (`dot_claude/modify_settings.json`,
  `dot_codex/private_hooks.json` → `agent-state` / `agent-stop-state`). Two turn
  endings fire no `Stop`: an **ESC interrupt** (anthropics/claude-code#9516) and a
  turn that dies on a terminal error, which goes to **`StopFailure`** instead
  (context past what compaction can rescue, a tool call that still won't parse
  after a retry). `StopFailure` is wired to red — the session is stuck and needs
  you, which is not an ordinary finished turn. The ESC case is covered by
  `agent-interrupt-state`, which spots the `[Request interrupted by user]` marker
  at the transcript tail, triggered from the Claude statusline refresh (fast path)
  and the `Notification[idle_prompt]` hook (~60s backstop). `Notification` also
  goes red on `worker_permission_prompt` and the two `elicitation_*` types — an
  MCP server asking a question through Claude blocks the turn as hard as a
  permission prompt and fires nothing else.
- **Antigravity (`agy`)** has no permission/notification hook event, so the dot
  is driven from its **status line** instead (`dot_gemini/antigravity-cli/executable_statusline.sh`),
  the one payload that exposes `agent_state`, `tool_confirmation_pending` (blocked
  on a tool approval), background tasks AND context % together. That script renders
  the ctx% status line *and* sets `@agent_state` as a side effect. `title.sh` sets
  the window title (inert in tmux — `allow-rename off` — useful outside it). Both
  are wired into `~/.gemini/antigravity-cli/settings.json` by
  `modify_private_settings.json`. agy ≥ 1.0.8 is required (statusline/title/hooks);
  the package script installs latest, older installs need `agy update`.

A companion `@agent_note` window option carries **what** the agent is doing, since
the dot only says whether it is doing anything — five working agents are five
identical blue dots. Agents set it themselves with `~/.local/bin/agent-note`,
instructed by the "Per-tab progress note" section of `agents/AGENTS.md`; nothing
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
Code exposes no ambient number for this (the status-line payload has no such
field, and the `tasks/*.output` files on disk outlive the task that wrote them),
but the **Stop hook payload carries `background_tasks`**, its own list of what is
still attached to the session, each entry typed `subagent` / `shell` /
`workflow` / …. So `agent-stop-state` — which already reads that array's length to
decide the dot — counts the `subagent` entries and hands the number to
`~/.local/bin/agent-subagents`. Recomputing from that list every turn is the whole
point: a counter incremented on spawn and decremented on finish drifts the first
time a process dies between the two and never recovers, whereas each Stop
overwrites the option with the truth. `agent-state none` unsets it with the dot
and the note, so a session killed mid-fan-out doesn't leave phantom subagents in
the bar. The number is Claude-only by construction — Codex and Antigravity tabs
count toward the `6` and can never add to the `+11`.

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
watching never flashes, and from `agent-state-sweep` every status tick as the
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

## Stale blue dots, and the one check that isn't an event

Every input above is an **event**, and an event that never arrives leaves the last
one standing — so the dot's failure mode is always the same shape: stuck on blue,
which is the worst way to be wrong, since blue reads as "leave this one alone" and
a finished agent goes unnoticed for as long as you believe it. Wiring
`StopFailure` closes one hole and `agent-interrupt-state` closes another, but
chasing holes one at a time never ends.

`~/.local/bin/agent-state-sweep` is the level-triggered backstop, and it works
because **Claude Code broadcasts its own state in the pane title**: a spinner
glyph (`◐◑◒◓`, U+25D0-25D3; braille on ≤ 2.1.227) while it works, and `✳` the
moment it stops. `tmux list-panes -a -F '#{pane_title}'` reads every pane's
current state in one call — no hook, no transcript, no ESC special case — and a
window claiming `running` while its Claude panes all show `✳` is simply wrong.
Whatever sequence of missed events got the option into that state, the next sweep
sets it right, because the title says what is true now rather than what happened
once. It runs from `tmux-agent-count` on the status-interval tick: the status bar
is the only thing tmux ticks on a timer, and a stale dot corrupts the count that
script renders anyway. It demotes `running` → `idle` only:

- **red is never touched.** A tab blocked on a permission prompt also shows `✳`,
  and turning "answer me" into "nothing to see here" is worse than a stale dot.
- **`@agent_bg` is honoured.** `agent-stop-state` sets it when a turn ends with
  agent-driven work still attached; that blue is deliberate, and Claude sits at
  the prompt showing `✳` the whole time — the exact shape the sweep demotes.
  `agent-state` drops the annotation on the next state change, so it can't outlive
  its reason.
- **non-Claude tabs are invisible to it.** Codex and Antigravity never write these
  titles, so nothing matches and their dots are left to their own hooks.

The same pass fixed a stale blue that had nothing to do with missing events.
`background_tasks` entries are typed, and a `shell` means the opposite of the
rest: a subagent, workflow or monitor is the agent's own work continuing and will
re-wake the session, while a `run_in_background` shell is the thing the agent
chose *not* to wait for — which is exactly what makes the turn over. Counting
shells as work pinned a tab blue for as long as a dev server stayed up. Only
non-shell tasks hold the dot now.

The pane-title signal and the "never latch, default to idle" principle come from
reading herdr, which drove Claude Code from these same lifecycle hooks, hit these
same stale-state bugs, and removed the hooks entirely in favour of screen
detection. See "Borrowed from herdr" below for what to re-check when Claude
changes its title glyphs again.

## Borrowed from herdr, and how to refresh it

Parts of the agent-dot design came from reading [herdr](https://github.com/herdrdev/herdr),
a terminal multiplexer that tracks coding-agent state for a living. **Read at
v0.8.1, commit `5203a5dc0f39a082938ea0f9836d6257ea7e155f`. Apache-2.0.** No files
were copied, so there is no licence obligation beyond this credit — but one piece
is upstream *data* that will go stale, and that is the row to care about.

| what we took | upstream | goes stale? |
| --- | --- | --- |
| The pane-title glyphs Claude Code broadcasts — `◐◑◒◓` working, `✳` stopped — used by `agent-state-sweep` | `website/agent-detection/claude.toml`, rules `osc_title_working` / `osc_title_idle` | **Yes.** Claude changed these once already (braille → half-circles at 2.1.228) |
| "Never latch: an unmatched screen means idle, never working" | `src/detect/manifest.rs`, `DEFAULT_KNOWN_AGENT_IDLE_FALLBACK` | No — a principle |
| `done` vs `idle` as finished-and-unseen vs finished-and-seen | `src/app/api_helpers.rs` `pane_agent_status`, `src/pane/state.rs` `seen` | No |
| The attention ladder `blocked > done > working > idle > unknown` | `src/app/api_helpers.rs`, `src/ui/sidebar.rs`, `src/workspace/aggregate.rs` | No |
| Debounce the working→idle edge (3 checks / 100ms, 700ms cap) — **considered and not taken**, see the note in `agent-state-sweep` | `src/pane/agent_detection.rs` | No |

**To refresh the glyphs**, don't clone the repo — herdr publishes the same
manifests over HTTP, which is the channel its own binary updates from:

```bash
curl -s https://herdr.dev/agent-detection/claude.toml | awk '/osc_title/,/^$/'
```

Compare the `regex` lines against the glyph list in
`~/.local/bin/agent-state-sweep`. We implement a deliberate subset — the
half-circles only, not the pre-2.1.228 braille range, and without upstream's
trailing-space requirement — so a diff is expected; what matters is whether
upstream has *added* a codepoint we don't match. The catalog at
`https://herdr.dev/agent-detection/index.toml` lists every agent they track,
including `codex.toml` and `antigravity.toml`, if the title trick is ever wanted
for those tabs too.

The symptom of a stale glyph list is a working tab going yellow while it is
plainly still busy (a new spinner codepoint stops matching, so the sweep reads
"not working"), or a finished tab staying blue (a new idle marker stops matching).

## The prefix+o overview, and its two views

`tmux-overview` has a **tree** view (the default) and the original **grid**
montage; **space** switches them and the choice sticks. The tree is one row per
tab under a foldable session header, carrying the dot, the name, the git branch
(peach `⑂ branch` in a linked worktree, the same marker `tmux-git-branch` puts in
the status bar), a sapphire `+3` for any subagents that tab has in flight, and a
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
- Guards against a stuck hold cooking the laptop in a bag: a 90-minute cap that
  latches off until the running count hits 0, a 30% battery floor, and the
  boot-reset daemon for the case where the guard dies mid-hold.

Only `running` counts — a red `needs-input` agent will never finish unattended.
Log: `~/Library/Logs/agent-sleep-guard.log`, written on transitions only.
