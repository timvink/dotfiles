---
name: remove-background
description: Cut out or mask a named subject with the local sam3 CLI on Apple Silicon, producing a transparent PNG. Use for background removal and object isolation.
---

# Remove a background with SAM 3

Use the chezmoi-managed `sam3` CLI. Processing is local; the first use may need to
download model weights. Run `sam3 doctor` for dependency and model-access checks.
If access to `facebook/sam3` is denied, follow its reported setup steps. The user
must complete any access form and accept the model license themselves.

## Choose the subject and inspect the output

Read the image before choosing a prompt. Use a concrete noun phrase describing
what to keep, such as `butterfly` or `coffee mug`, rather than a sentence describing
its location. Include connected objects with repeated `-p` options; masks are
unioned.

```sh
sam3 cutout photo.jpg -p 'coffee mug' -o mug.png --check /tmp/mug-check.png
sam3 cutout portrait.jpg -p person -p hat -o portrait.png
```

The result path goes to stdout; scores and progress go to stderr. Without `-o`,
output is `<input-name>-cutout.png` beside the input. PNG is required for alpha.

Open the checkerboard preview to verify transparency, subject coverage, and edge
quality. Keep previews in scratch space or `/tmp`. To inspect detected instances
before making a cutout:

```sh
sam3 segment photo.jpg -p 'coffee mug' --preview /tmp/found.png
```

## Adjust a mask

`--threshold` selects instances; `--mask-threshold` selects pixels within those
instances. If nothing matches, try a broader noun before lowering the threshold.

| Symptom | Adjustment |
| --- | --- |
| Fine parts missing, such as antennae or hair | Try `--mask-threshold 0.15` |
| Fringe from the old background | Try `--grow -1` |
| Hard edge on a photograph | Try `--feather 1` |
| Extra objects selected | Use `--top 1`, or raise `-t 0.7` |
| Entire subject missed | Broaden the prompt, then try `-t 0.3` |
| Need a tighter output canvas | `--crop --pad 20` |

Reinspect after adjustments. Leave feathering off for crisp artwork unless the
result needs it; a setting that helps a photograph can damage a logo.

## Limits

Masks retain the original image size. Use `--device cpu` if MPS fails, accepting
slower processing. Override a checkpoint with `--model` or `SAM3_MODEL` only when
appropriate for the installed CLI and model access.

The CLI does not expose video or point/box prompts. For a truly uniform background,
consider a color-key operation instead of segmentation when available and allowed
by the task's image-editing tools.
