-- Rex configuration. Reload with `rex config reload` (Rex doesn't watch this file).

-- Write raw bytes to the focused terminal, as if typed.
local function typer(data)
  return function(ctx)
    if not ctx.block_id then return false end
    rex.block.call("com.superlogical.terminal", "write", {
      session_id = ctx.session_id, block_id = ctx.block_id, data = data,
    })
    return true
  end
end

-- Alt+Left/Right → modified-cursor CSI (ESC[1;3D / ESC[1;3C) instead of the
-- readline ESC b / ESC f Rex sends by default. ESC f is byte-identical to Alt+f,
-- so tmux's `M-f` sessionizer popup fired on Alt+Right. Mirrors the Ghostty
-- keybinds (dot_config/ghostty/config); zsh rebinds word motion onto these
-- sequences (dot_zshrc.tmpl).
rex.bind("alt+left", typer("\27[1;3D"))
rex.bind("alt+right", typer("\27[1;3C"))

-- Shift+Enter → bare LF (what Ctrl+J sends): newline, not submit. Rex sends a
-- plain CR otherwise, which submits in Claude Code. Mirrors Ghostty's
-- `shift+enter=text:\n`; LF passes through tmux without needing extended keys.
rex.bind("shift+enter", typer("\n"))
