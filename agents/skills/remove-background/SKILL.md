---
name: remove-background
description: >-
  Remove the background from an image on this Mac, producing a transparent PNG,
  using Meta's SAM 3 through the local `sam3` CLI. Use when asked to cut out a
  subject, remove or delete a background, make an image transparent, isolate an
  object, extract a logo or product shot, or produce a PNG with alpha. Also use
  it to find or mask a named object in an image. Runs offline on Apple Silicon
  (MPS); no upload, no API key.
---

# Remove backgrounds with SAM 3

[SAM 3](https://huggingface.co/facebook/sam3) segments by *concept*: you give it
a short noun phrase and it returns a mask for every matching instance. The
chezmoi-managed `sam3` CLI (`~/.local/bin/sam3`, a `uv run --script` file) wraps
that into a background remover.

Everything runs on-device. The first call downloads ~3.5 GB of weights and takes
a minute or two; later calls are a few seconds on MPS.

## Before the first run

The weights sit behind Meta's gate on Hugging Face. Check with:

```sh
sam3 doctor
```

If it prints `hf access DENIED`, the user has to open
<https://huggingface.co/facebook/sam3>, submit the access form and add a token —
`doctor` prints the steps. **Don't fill that form in for them**: it asks for
their name, date of birth and country, and it accepts a license on their behalf.

Approval is granted on this Mac and the token is in `~/.cache/huggingface/token`,
so `facebook/sam3` works as the default. On a machine where it hasn't cleared —
Meta approves by hand and it can sit pending — the same weights are mirrored
ungated and produce a pixel-identical mask:

```sh
sam3 cutout photo.jpg -p "butterfly" --model Translsis/sam3-model
```

## Cut out a subject

```sh
sam3 cutout ~/Downloads/photo.jpg -p "butterfly" -o ~/Downloads/butterfly.png
```

The path of the PNG goes to stdout; progress and scores go to stderr. Without
`-o` the result lands next to the input as `<name>-cutout.png`.

## Pick the prompt from the picture, not the filename

This is the whole job. SAM 3 keeps what matches the phrase and drops everything
else, so a wrong noun gives an empty or half-right mask.

1. Read the image first. Look at what the subject actually is.
2. Use a plain, concrete noun phrase: `butterfly`, `coffee mug`, `person`,
   `sneaker`, `dog`. Two or three words at most.
3. Don't describe the background, and don't write a sentence. `the butterfly in
   the middle of the vintage print` scores worse than `butterfly`.
4. If the subject has parts the mask should keep — a person plus their hat, a
   bike plus its rider — pass `-p` more than once. The masks are unioned:

   ```sh
   sam3 cutout portrait.jpg -p person -p hat -o portrait.png
   ```

If nothing matches, the CLI says so and exits 1. Try a broader noun before you
lower `--threshold`.

## Always look at the result

A transparent PNG viewed against a white page looks identical to one that failed.
Write a checkerboard copy and read that:

```sh
sam3 cutout photo.jpg -p "coffee mug" -o mug.png --check /tmp/mug-check.png
```

Open `/tmp/mug-check.png` with the Read tool. Grey squares are transparency.
Check for a background fringe, holes in the subject, and missing thin parts
(antennae, hair, handles). Put the check file in the scratchpad or `/tmp`, never
next to the user's image.

To see what SAM 3 found before committing to a cutout:

```sh
sam3 segment photo.jpg -p "coffee mug" --preview /tmp/found.png
```

That prints one JSON record per instance (score, box, area) and draws the masks
on the image.

## Fixing a mediocre mask

The two thresholds do different jobs, and mixing them up is the usual mistake.
`--threshold` decides *which instances* survive; `--mask-threshold` decides
*which pixels* belong to an instance that already survived.

| Symptom | Fix |
| --- | --- |
| Thin parts missing: antennae, hair, wires, whiskers | `--mask-threshold 0.15` |
| Halo of old background around the edge | `--grow -1` (erodes 1 px) |
| Hard, aliased edge | `--feather 1` |
| Extra objects came along | `--top 1`, or raise `-t 0.7` |
| Subject missed entirely | broader noun, then `-t 0.3` |
| Speckles of background elsewhere | `--top N` for the N you actually want |
| Want it tight to the subject | `--crop`, plus `--pad 20` for breathing room |

The first row matters more than it looks. At the default `--mask-threshold 0.5`
SAM 3 clips anything only a pixel or two wide — on a monarch butterfly it
silently amputates both antennae. Dropping to `0.15` restores them whole and
costs almost nothing elsewhere, so reach for it whenever the subject has fine
edges.

`--grow -1 --feather 1` together is a good default for photos with a busy
background. Leave both off for flat artwork and logos — feathering softens crisp
line work.

## Notes

- Output must be `.png`. JPEG has no alpha channel and the CLI refuses it.
- Non-square and large images are fine; masks come back at the original size.
- `--device cpu` if MPS misbehaves. It works, just slower.
- Point at a different checkpoint with `--model <repo>` or `SAM3_MODEL=<repo>`.
- Video and point/box prompts are SAM 3 features this CLI does not expose yet.

## When not to use this

Removing a *uniform* background (a studio white or a green screen) is a colour
key, not a segmentation problem — ImageMagick does it faster and with a cleaner
edge. Reach for SAM 3 when the background is real scenery, or when you need one
named object out of several.
