---
name: proton-mail
description: >-
  Read, search, draft (with attachments), archive, and send Proton Mail from the
  user's already-open, logged-in Proton tab via the local `proton-bridge` CLI
  (companion Firefox extension). Use when the user asks to check / read / search
  their Proton email, summarize their inbox, find a message, draft or send a
  reply, attach a file, or archive a message. Sending is irreversible and gated
  on explicit per-message intent; it never deletes (archive is the only
  destructive-ish action, and it's reversible). Requires Firefox open with
  https://mail.proton.me logged in.
---

# Proton Mail (local bridge)

This skill talks to a Firefox extension that reads the user's **already-decrypted**
Proton Mail tab. No Proton Bridge, no IMAP, no credentials — the web app decrypts
in the browser and the extension reads the rendered DOM. Communication goes through a
native-messaging host over local pipes (no network port); nothing runs continuously.

## Before using

Requires all of:
1. **Firefox open** with a tab on `https://mail.proton.me`, **logged in**.
2. The **Proton LLM Bridge extension** installed, and the **native host** registered
   (`make install-host`, done once during setup).
3. The **`proton-bridge` CLI** on PATH (via `uv tool install ./cli`).

Sanity-check first with `proton-bridge ping`. If it reports `loggedIn: false` or
times out, tell the user what's missing instead of retrying blindly. A
`Connection refused` from `ping` usually means the **extension isn't loaded** in
the running Firefox (the host is spawned by the extension) — ask the user to
load/enable it (`about:debugging` → Load Temporary Add-on → `extension/manifest.json`,
or install a signed `.xpi`).

## Commands

All commands print JSON to stdout (exit 0) or a JSON error to stderr (exit 1).

| Command | What it does |
|---|---|
| `proton-bridge ping` | Check the bridge and whether the user is logged in. |
| `proton-bridge list [--limit N]` | List messages in the current view (id, subject, conversationCount, sender, date, unread). |
| `proton-bridge goto FOLDER [--limit N]` | Navigate to a mailbox folder (`inbox`, `all-mail`, `starred`, `archive`, `sent`, `drafts`, `trash`, `spam`, …) and list it. |
| `proton-bridge read [ID]` | Read a message. With an ID from `list`, it opens that row first; with no ID, reads whatever message is currently open. Returns plaintext `body`. |
| `proton-bridge search "QUERY" [--limit N]` | Run Proton's search and list the results. |
| `proton-bridge archive ID` | Move a message to the **Archive** folder. Reversible. Requires an ID from `list`. |
| `proton-bridge draft --to "a@b.com" --subject "..." --body "..."` | Open a **prefilled composer**. Also `--body-file PATH` and `--attach PATH` (repeatable; each file < ~700 KB). Does **not** send. |
| `proton-bridge send [--force]` | Click **Send** on the open composer. **Irreversible.** Refuses if several composers are open unless `--force` (then sends the newest). |
| `proton-bridge diagnose` | Report which DOM selectors matched — use when output looks wrong. |

## Sending — read this before you ever run `send`

`send` is the one irreversible action this tool has. Treat it like archive's
stricter sibling:

- **Explicit per-message intent only.** Run `send` only when the user has clearly
  asked to send *this* message. Never as a side effect of a vague request.
- **Draft → review → send.** Always `draft` first (it leaves the composer open and
  prefilled). Before sending, state the **recipient, subject, and any attachments**
  back to the user and get a clear go-ahead. Default to leaving the draft for the
  user when there's any doubt.
- **`send` acts on the open composer** — it does not take to/subject/body. So the
  immediately-preceding `draft` defines what goes out. Don't `send` if you're not
  sure which composer is open (it will refuse when more than one is open).
- **Attachments ride inside the message** (base64), so they're capped near 1 MB
  each. Larger files: tell the user to attach manually, or share a link instead.

## Other constraints

- **Never deletes.** Archive (reversible) is the only move-to-folder action. There
  is no trash, spam, or permanent-delete command — do not look for workarounds.
- **Archive needs per-message intent too.** Only `archive` when asked; confirm the
  subject first. Never archive as a side effect of "clean up my inbox."
- If `read` returns `bodyExtractionFailed: true` or an empty `body` with
  `bodySource: "iframe-blocked"`, the body lives in a sandboxed iframe the
  extension couldn't read. Report it; do not fabricate. Run `diagnose` and surface
  the result so the selectors can be fixed.

## Typical flows

- *"What's in my inbox?"* → `ping`, then `list`, summarize.
- *"Read the one from Alice."* → `list`, pick the matching `id`, `read <id>`.
- *"Find emails about the invoice."* → `search "invoice"`, then `read <id>`.
- *"Draft a reply to Bob saying I'll be late."* → confirm intent, `draft --to ... --subject ... --body ...`, tell the user it's open for review.
- *"Email this file to Carol and send it."* → `draft --to carol@... --subject ... --body ... --attach /path/to/file`; confirm recipient + subject + attachment with the user; on their go-ahead, `send`.
- *"Archive that newsletter."* → `list` (or `search`), identify the `id`, confirm the subject, then `archive <id>`.

## Troubleshooting

- `ping` says `Connection refused` → extension not loaded in the running Firefox
  (re-load/enable it); host manifest unregistered (`make install-host`); or the
  launcher's `python3` path moved.
- Timeout → Firefox not open, Proton tab not loaded, or extension not installed.
- `send` clicked but composer stayed open → likely a missing recipient or still
  uploading an attachment; check the tab. `attachWarning` on a draft → the file
  input wasn't found; run `diagnose` and re-tune `composerAttachmentInput`.
- Empty/garbled fields → Proton changed its DOM; run `diagnose` and update the
  extension's `selectors.js`.
