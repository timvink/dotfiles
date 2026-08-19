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

A coloured dot per tmux tab shows each agent's state (blue ● working, red ●
needs input, yellow ○ your turn), driven by the `@agent_state` window option that
`window-status-format` reads (`dot_tmux.conf`). It's set by `~/.local/bin/agent-state`:

- **Claude Code / Codex** drive it from lifecycle hooks (`dot_claude/modify_settings.json`,
  `dot_codex/private_hooks.json` → `agent-state` / `agent-stop-state`). One gap:
  Claude Code fires **no hook on an ESC interrupt** (anthropics/claude-code#9516),
  which would leave the dot stale blue/red. `agent-interrupt-state` covers it by
  spotting the `[Request interrupted by user]` marker at the transcript tail —
  triggered from the Claude statusline refresh (fast path) and the
  `Notification[idle_prompt]` hook (~60s backstop).
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
