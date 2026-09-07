---
name: proton-mail
description: Read, search, draft, send, or archive Proton Mail through the local proton-bridge CLI and the user's logged-in Firefox tab. Sending requires explicit intent for the message.
---

# Proton Mail

Run `proton-bridge ping` first. Firefox must have a logged-in `mail.proton.me`
tab and the bridge extension must be active. If unavailable, consult
[references/setup.md](references/setup.md); don't retry without addressing the
reported cause. The bridge reads the already-decrypted browser content.

## Commands

Commands return JSON; inspect errors and warnings as well as the exit status.

| Command | Purpose |
| --- | --- |
| `proton-bridge list [--limit N]` | List messages in the current view |
| `proton-bridge goto FOLDER [--limit N]` | Navigate to inbox, sent, archive, or another folder |
| `proton-bridge search "QUERY"` | Find messages |
| `proton-bridge read [ID]` | Open and read an ID, or read the currently open message |
| `proton-bridge draft --to ADDRESS --subject TEXT --body-file PATH` | Open a filled composer without sending |
| `proton-bridge archive ID` | Archive a specified message |
| `proton-bridge send` | Send the open composer |
| `proton-bridge diagnose` | Inspect DOM selector matches |

Drafts also accept `--body TEXT` and repeated `--attach PATH`. Keep attachments
under approximately 700 KB each for this bridge; inspect attachment warnings and
verify that uploads completed. Larger files need manual attachment or a shared link.

## Sending and archiving

Send only when the user explicitly asks to send the particular message. An
already-authorized request with a clear recipient and content needs no repeated
confirmation. A draft request authorizes drafting only. Resolve ambiguous recipients,
content, or attachments before sending.

Draft first, then verify recipient, subject, body, and attachments in the composer.
`send` acts on the open composer, not an ID; don't send an unrelated draft. If
several composers are open, resolve the ambiguity instead of using `--force`.
Check the result and report any failure; don't claim delivery from a draft alone.

Archive when the request identifies the messages to archive; use returned IDs and
verify their subjects. Don't infer bulk archive permission from “clean up my inbox.”
The bridge has no delete command; don't work around that constraint.

## Read failures

If `read` reports `bodyExtractionFailed`, or an empty body with
`bodySource: "iframe-blocked"`, report the unreadable body and run `diagnose`.
Don't infer its contents from the subject. Selector failures may require a bridge
fix; an attachment warning does not establish a successful upload.
