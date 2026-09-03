---
description: Rewrite text in ASD-STE100 Simplified Technical English (or check it against the rules)
argument-hint: [file or text to rewrite | "check <file>"]
---
Target: $ARGUMENTS

Read `~/.claude/simple-english/SKILL.md` and follow it for this task. Its
`references/*.md` files sit next to it in `~/.claude/simple-english/`; read one
when the SKILL tells you to.

If no target is given above, apply it to the text or file we were last working
on; ask which one only if that is genuinely unclear.

The SKILL's rules replace the `write-for-humans` skill for this task — do not
load both.
