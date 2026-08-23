// /exit + alt+e — leave this session and close the hosting shell/tmux window.
//
// Two-phase exit: ctx.shutdown() runs first so every extension's
// session_shutdown handler fires (MCP servers etc. clean up properly), then a
// detached kill-pane tears down the pane tree (pi, launching shell) a second
// later. Outside tmux, delegate to ~/.local/bin/agent-exit, which SIGHUPs the
// host shell the same way it does for Claude/Codex.
import { spawn } from "child_process";

export default function (pi) {
	const leave = async (_args, ctx) => {
		ctx.shutdown();
		if (process.env.TMUX_PANE) {
			spawn("bash", [
				"-c",
				'sleep 1; tmux kill-pane -t "$TMUX_PANE" 2>/dev/null || ~/.local/bin/agent-exit',
			], { detached: true, stdio: "ignore" }).unref();
		} else {
			spawn("$HOME/.local/bin/agent-exit", [], {
				detached: true,
				stdio: "ignore",
				shell: "/bin/bash",
			}).unref();
		}
	};
	pi.registerCommand("exit", { description: "Quit pi and close the tab", handler: leave });
}
