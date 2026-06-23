---
name: proton-mail
description: >-
  Read, search, draft, and archive Proton Mail from the user's already-open,
  logged-in Proton tab via the local `proton-bridge` CLI (companion Firefox
  extension). Use when the user asks to check / read / search their Proton email,
  summarize their inbox, find a specific message, draft a reply, or archive a
  message. Never sends and never deletes — archive (reversible) is the only
  mutation besides drafting. Requires Firefox open with https://mail.proton.me
  logged in.
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
times out, tell the user what's missing instead of retrying blindly.

## Commands

All commands print JSON to stdout (exit 0) or a JSON error to stderr (exit 1).

| Command | What it does |
|---|---|
| `proton-bridge ping` | Check the bridge and whether the user is logged in. |
| `proton-bridge list [--limit N]` | List messages in the current view (id, subject, conversationCount, sender, date, unread). |
| `proton-bridge goto FOLDER [--limit N]` | Navigate to a mailbox folder (`inbox`, `all-mail`, `starred`, `archive`, `sent`, `drafts`, `trash`, `spam`, …) and list it. Use this to read the inbox if the tab is on some other view. |
| `proton-bridge read [ID]` | Read a message. With an ID from `list`, it opens that row first; with no ID, reads whatever message is currently open. Returns plaintext `body`. |
| `proton-bridge search "QUERY" [--limit N]` | Run Proton's search and list the results. |
| `proton-bridge archive ID` | Move a message to the **Archive** folder. Reversible. Requires an ID from `list`. |
| `proton-bridge draft --to "a@b.com" --subject "..." --body "..."` | Open a **prefilled composer**. Also `--body-file PATH`. |
| `proton-bridge diagnose` | Report which DOM selectors matched — use when output looks wrong. |

## Hard constraints

- **Never sends.** `draft` only opens a prefilled composer for the user to review
  and send themselves. There is no send command. Do not look for workarounds.
- **Never deletes.** Archive (reversible) is the only mutation. There is no
  trash, spam, or delete command — do not look for workarounds.
- **Mutations require explicit per-message intent.** Only `draft` or `archive`
  when the user asks you to. Never archive as a side effect of a vague request
  like "clean up my inbox" — confirm each message first, naming its subject.
- If `read` returns `bodyExtractionFailed: true` or an empty `body` with
  `bodySource: "iframe-blocked"`, the message body lives in a sandboxed iframe the
  extension couldn't read. Report this; do not fabricate the body. Run
  `proton-bridge diagnose` and surface the result so the selectors can be fixed.

## Typical flows

- *"What's in my inbox?"* → `ping`, then `list`, summarize.
- *"Read the one from Alice."* → `list`, pick the matching `id`, `read <id>`.
- *"Find emails about the invoice."* → `search "invoice"`, then `read <id>` as needed.
- *"Draft a reply to Bob saying I'll be late."* → confirm intent, `draft --to ... --subject ... --body ...`, tell the user it's open for review.
- *"Archive that newsletter."* → `list` (or `search`), identify the `id`, confirm the subject with the user, then `archive <id>`.

## Troubleshooting

- Timeout → Firefox not open, extension not installed, or secret not set (see repo README).
- Empty/garbled fields → Proton changed its DOM; run `diagnose` and update the
  extension's `selectors.js`.
