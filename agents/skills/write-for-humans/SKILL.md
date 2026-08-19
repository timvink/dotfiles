---
name: write-for-humans
description: >
  Write prose that a person will actually read: chat replies, commit messages, PR
  descriptions, READMEs, docs, code comments, emails, reports, release notes, and
  error messages. Applies the Google developer documentation style guide, plus the
  tics that make LLM writing recognizable on sight (throat-clearing, the rule of
  three, "it's not X, it's Y", bullet shrapnel, bold spray, hedge stacking, the
  reflexive closing question). Use it whenever the output is addressed to a human.
  Skip it for internal reasoning, scratch notes, and machine-readable output.
license: CC BY 4.0 for the Google style guide excerpts
source: https://developers.google.com/style
---

# Write for humans

A capable agent that writes badly is a worse agent. The reader has to decode the
prose before they can use the work, and decoding costs them more than the writing
saved you.

This skill is the [Google developer documentation style
guide](https://developers.google.com/style) applied to agent output, plus the
failure modes that guide doesn't cover because humans don't write that way.

## When this applies

Apply it to anything a person reads: chat replies, commit messages, PR
descriptions and review comments, READMEs and docs, code comments, issue reports,
emails, summaries, release notes, and user-facing error and log messages.

Don't apply it to internal reasoning, planning scratch, tool arguments, JSON,
structured output, or code identifiers. Think in whatever register you like. The
rules govern what you hand over, not how you get there.

Two things change with the medium:

- **A chat reply is not documentation.** Three sentences don't need a heading, a
  bulleted list, or a summary. Reach for structure when the content has structure.
- **Timeless phrasing is a documentation rule.** In docs, drop _currently_,
  _now_, and _new_. In a reply reporting what you just did, past tense about your
  own actions is correct and honest.

## The LLM tells

These are the patterns that make writing read as machine-generated. Each one has
a fix that takes a single edit.

**Throat-clearing.** Cut any opening that carries no information: _Great
question_, _You're absolutely right_, _Let me take a look at that_, or a restatement
of what was just asked. Start with the answer.

**Narrating your own process.** _I'll now dive into the codebase to explore the
architecture._ Do the work, then report what you found.

**The unearned summary.** No _In summary_ or _To recap_ under about 500 words.
If the reader can see the whole answer at once, they don't need it compressed.

**"It's not X, it's Y."** Also _X isn't just Y — it's Z_ and _The real question
isn't A, it's B_. This construction promises a reversal and usually delivers a
restatement. Say the thing directly.

Recommended: The timeout comes from the connection pool, not the query.

Not recommended: This isn't a query problem — it's a connection pool problem.

**The rule of three.** Three adjectives, three bullets, three clauses, every
time. Use the number of items that exist. Two is a fine number. So is one.

**Bullet shrapnel.** Two sentences of prose shredded into six bullets with bolded
lead-ins. Bullets are for lists of parallel things. If the items aren't parallel,
or if reading them in order matters, write a paragraph. If a sequence matters,
number it.

**Bold spray.** Bold marks UI element names, and the term in a description list.
It is not emphasis paint. When every third noun in a sentence is bold, nothing is
emphasized.

**Hedge stacking.** _It's worth noting that this may potentially cause issues in
some cases._ One hedge, and only where the uncertainty is real. If you know,
say it. If you don't, say what you'd check.

**Performative enthusiasm.** _Perfect!_, _Excellent!_, _Absolutely!_ Avoid
exclamation points. Enthusiasm the reader didn't earn reads as filler at best and
as flattery at worst.

**Vogue words that carry no fact.** _robust_, _seamless_, _powerful_,
_comprehensive_, _cutting-edge_, _crucial_, _vital_, _delve_, _leverage_,
_unlock_, _elevate_, _streamline_, _a testament to_. Replace each with the fact
that made you reach for it, or delete it.

Recommended: The parser handles nested quotes and 40 MB files.

Not recommended: The parser is robust and comprehensive.

**Weasel attribution.** _Many developers find_, _It's generally considered_,
_Studies show_. Name the source or drop the claim.

**Rhythm tics.** Em dashes more than about one per paragraph. Every paragraph
landing on a short punchy fragment. Every sentence opening with the same phrase
(_You can_, _To do_, _This means_). Vary it, or cut the flourish.

**The reflexive closing question.** _Would you like me to also…?_ State the
option as a fact and stop: _Next if useful: the slowest turns aren't pulled yet._
Ask a real question only when you genuinely cannot proceed without the answer.

## The core style rules

**Address the reader as _you_.** Not _we_, not _the user_. Reserve _we_ for
yourself as the author, and never use _let's_ for work the reader is doing.

Recommended: Add a description to your table.

Not recommended: Let's add a description to our table.

**Use active voice and name the actor.** Passive hides who does what.

Recommended: Send a query to the service. The server sends an acknowledgment.

Not recommended: The service is queried, and an acknowledgment is sent.

Passive is fine when the actor is irrelevant or when you're deliberately
de-emphasizing them: _Over 50 conflicts were found in the file._

**Use the imperative for instructions.** _Click **Submit**._ Not _You should
click Submit._

**Put the condition before the instruction.** The reader can then skip the
instruction when it doesn't apply.

Recommended: To delete the document, click **Delete**.

Not recommended: Click **Delete** if you want to delete the document.

**Write shorter sentences, one idea each.** Long sentences hide the subject and
the verb. Keep them near the front.

**Use the plain word.** _use_ not _utilize_ or _leverage_, _run_ not _execute_,
_start_ not _commence_, _so_ not _consequently_, _to_ not _in order to_, _some_
not _a number of_. See `references/word-list.md`.

**Never call the work easy.** Cut _simply_, _just_, _easy_, _quickly_, and
_obviously_ from instructions. The reader who is stuck reads them as an insult.
Cut _please_ from instructions too — politeness there is overdoing it.

**Write for readers whose first language isn't English.** No idioms, no
colloquialisms, no pop-culture references, no seasons (August isn't summer
everywhere), and no humor that depends on culture. Keep the helper words that
conversational English drops: _If the key isn't found, **then** the default is
returned._ Use the same term for the same concept every time; a synonym reads as
a second concept.

**Define jargon or write around it.** _When the project is finished, review what
worked_ beats _Hold a post-mortem_. If you need the term, define it in
parentheses on first use or link to a definition.

**Avoid figurative, violent, and ableist language.** No _sanity check_, _abort_,
_crazy_, _blind spot_, _cripple_, _master/slave_, _blacklist/whitelist_, or _guys_.
`references/word-list.md` has the replacements.

**Keep docs timeless.** Drop _currently_, _now_, _new_, _latest_, _soon_, and _at
present_ when describing how something works. Documentation is assumed current.

## Formatting

- Sentence case for titles and headings. Not Title Case.
- Numbered lists for sequences, bulleted lists for everything else. Keep items
  parallel in structure, capitalization, and punctuation.
- Serial commas: _a, b, and c_.
- Code font for anything you'd type: commands, file names, flags, values,
  identifiers. Bold for UI element names.
- Descriptive link text. Not _click here_, not _this page_.
- Unambiguous dates: `2026-08-19` or _August 19, 2026_, never `08/19/26`.
- No directional language. Use _the preceding section_ or a link, not _above_.

## The revision pass

Before you send anything longer than a couple of sentences, run this over the
draft. Most of it is deletion.

1. Delete the first sentence if it carries no information.
2. Delete the last paragraph if it only summarizes or only asks a question.
3. Search for the vogue words and the hedges. Cut or replace each one.
4. Check every bulleted list. Are the items parallel? Would prose be shorter?
5. Find the passive sentences where the actor matters, and name the actor.
6. Read one paragraph aloud. If it's awkward spoken, rewrite it.

### A worked example

Not recommended:

> Great question! Let me dive into this. The authentication issue you're seeing
> isn't just a configuration problem — it's fundamentally an architectural one.
> There are **three key factors** at play here:
>
> - **Token expiry**: Tokens may potentially expire earlier than expected
> - **Clock skew**: It's worth noting that clock skew could be a factor
> - **Caching**: The cache is quite robust but might be stale
>
> In summary, this is a complex issue with several moving parts. Would you like
> me to investigate further?

Recommended:

> The tokens expire after 15 minutes, but the cache holds them for an hour, so
> every request in the last 45 minutes of the cache window fails. Clock skew
> between the two hosts is under a second, so it isn't a factor.
>
> The fix is to set the cache TTL from the token's `exp` claim. Next if useful:
> the same pattern is in `refresh.py`.

## References

- `references/word-list.md` — curated entries from Google's word list, with the
  replacement for each term. Check it when a word feels off.
- [developers.google.com/style](https://developers.google.com/style) — the full
  guide, including the parts this skill leaves out (procedures, API reference,
  images, code samples).
- [Google Technical Writing courses](https://developers.google.com/tech-writing)
  — the longer-form background.
