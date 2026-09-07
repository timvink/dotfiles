---
name: frontend-design
description: Design a new UI or substantially reshape an existing one with deliberate typography, layout, and visual identity. Preserve established designs for routine fixes.
license: Complete terms in LICENSE.txt
source: https://github.com/anthropics/skills/tree/main/skills/frontend-design
local-edits: Shortened to content-led design decisions, accessibility, and visual review; removed fictional backstory and mandatory uniqueness exercises.
---

# Frontend design

Ground the design in the subject, audience, and page's main job. Use the brief's
content and existing brand; if those are unspecified, state a reasonable choice.
A routine UI fix should follow the existing design system.

## Choose a direction

Before building a new design, choose a compact palette, a type scale, and a layout
that serve its content. Keep this planning mostly internal unless a choice needs
the user's input. Wireframes help when comparing materially different layouts.

Typography and spacing should establish hierarchy. Pair fonts deliberately when
useful; extra typefaces aren't a requirement. Use numbering, labels, and dividers
only when they communicate structure. A sequence deserves numbers; unrelated
cards do not.

Give a new visual identity one memorable element suited to its subject, with
quieter supporting elements. Don't force novelty at the expense of usability or
the brief. Avoid automatically reaching for cream-and-serif, dark-and-neon, or
newspaper layouts; each is valid when the content or user calls for it.

Match implementation complexity to the design. Use motion to explain a change,
provide feedback, or support the subject. Respect reduced motion and omit
animation that only adds delay or distraction.

## Build and inspect

Use consistent design tokens and predictable CSS specificity. Check responsive
layout, contrast, visible keyboard focus, and interaction states. Inspect rendered
screenshots when available; fix overflow, alignment, and spacing against what
actually rendered. Remove decoration that does not help the page.

## Interface copy

Use the user's vocabulary: “notifications,” rather than implementation terms
such as “webhooks,” unless the implementation is what they manage. Name actions
consistently across controls and feedback: “Publish” produces “Published.”

Labels should explain the action. Empty states should show the next useful step;
errors should explain what happened and how to recover. Follow `write-for-humans`
for prose without adding marketing filler to ordinary controls.
