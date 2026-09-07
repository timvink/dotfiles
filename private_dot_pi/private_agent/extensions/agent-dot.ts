// agent-dot — drive the tmux per-tab agent dot from pi's lifecycle events.
//
// The dot is the same one Claude Code and Codex feed via lifecycle hooks and
// Antigravity feeds from its status line (see ~/.local/bin/agent-state and
// dot_tmux.conf). pi exposes no shell-out hooks, but its extension
// events map onto the four states we can express without an interactive
// blocker:
//
//   session_start      → none   fresh session shows no dot; a reused window
//                               drops any stale state from the prior session
//   before_agent_start → running turn begins the moment you press enter
//   agent_settled      → done   "settled", not "end": pi may auto-retry,
//                               auto-compact or continue with queued follow-up
//                               messages after a low-level run ends, and only
//                               settled means it won't. done ● then opens to
//                               idle ○ via agent-seen once you look at the tab.
//   session_shutdown   → none   /new, /resume, fork, quit — clear as you go
//
// No red: pi has no permission-prompt event an extension can observe, so
// needs-input stays reserved for the agents that can report it. No pane-title
// signal either — pi never writes spinner glyphs — so agent-state-sweep is
// blind here by design; the zsh precmd reaper covers the exit-that-fires-
// nothing case, exactly as it does for Codex.
//
// Outside tmux every call is a no-op inside agent-state itself; the TMUX_PANE
// check here just saves the spawn. Fire-and-forget: a failed tmux call must
// never surface as an error inside pi.

import { execFile } from "node:child_process";

const AGENT_STATE = `${process.env.HOME}/.local/bin/agent-state`;

function set(state: string): void {
	if (!process.env.TMUX_PANE) return;
	execFile(AGENT_STATE, [state], () => {});
}

export default function (pi: {
	on(event: string, handler: () => void | Promise<void>): void;
}) {
	pi.on("session_start", () => set("none"));
	pi.on("before_agent_start", () => set("running"));
	pi.on("agent_settled", () => set("done"));
	pi.on("session_shutdown", () => set("none"));
}
