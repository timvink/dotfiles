// /exit — alias for the built-in /quit behavior.
export default function (pi) {
	pi.registerCommand("exit", {
		description: "Quit pi (alias for /quit)",
		handler: async (_args, ctx) => {
			ctx.shutdown();
		},
	});
}
