---
name: pptx
description: Read, create, or edit PowerPoint .pptx decks and .potx templates, including slide content, layouts, charts, and speaker notes.
license: Proprietary. LICENSE.txt has complete terms
source: https://github.com/anthropics/skills/tree/main/skills/pptx
local-edits: Split creation, editing, design, and QA references; preserve local chart validation, template handling, and scripts. Check dependencies and fonts instead of assuming a preconfigured environment.
---

# PowerPoint files

Choose the workflow needed for the task. Resolve script paths against this skill's
root directory and use a task-specific scratch directory for intermediate files.

| Task | Workflow |
| --- | --- |
| Read text | `markitdown deck.pptx`; no authoring references needed |
| Inspect layouts | `scripts/thumbnail.py deck.pptx deck-thumbs`; give each deck a unique output prefix |
| Create a deck | Read [references/creation.md](references/creation.md) before using pptxgenjs |
| Edit a deck or fill a template | Read [references/editing.md](references/editing.md) before changing the package |
| Choose visual presentation | Read [references/design.md](references/design.md) for new designs or substantial layout changes |
| Verify a generated or edited file | Follow [references/quality.md](references/quality.md) |

## File constraints

PowerPoint packages contain XML parts linked by relationships. Use
`scripts/add_slide.py` for duplication and `scripts/clean.py` after finalizing the
slide list; copying a slide XML file alone misses package registration. Pass
`-o` to `add_slide.py` when preserving the input deck.

After writing, run `scripts/office/validate.py output.pptx`. For template-derived
files, add `--original template.pptx` so inherited schema errors don't hide new
ones. Read structural failures separately; they are not suppressed by that flag.
A successful LibreOffice render alone does not establish PowerPoint compatibility.

Use native charts where PowerPoint supports the chart type. Preserve template
formatting and inspect affected slides for overflow, placeholders, and missing
content. A text-extraction task needs neither file rewriting nor authoring QA.

## Dependencies

Check available packages before installing anything. Depending on the workflow,
you may need `pptxgenjs`, `markitdown[pptx]`, Pillow, defusedxml, lxml, LibreOffice,
or Poppler's `pdftoppm`. Use the project's environment or temporary task
dependencies; persistent machine setup goes through chezmoi.

The `scripts/office/soffice.py` wrapper supports environments where bare
LibreOffice hangs. Font availability varies; check it before trusting render
metrics. For thumbnailing a `.potx`, use a scratch copy named `.pptx`.
