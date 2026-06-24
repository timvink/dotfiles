---
name: transcribe
description: >-
  Transcribe audio or video to text locally on this Mac using the Whisper
  large-v3 model the Handy app already downloaded — fully offline, no cloud, no
  API key. Use when asked to transcribe a recording, audio/video file, voice
  memo, podcast, or interview, or to get a transcript on this machine.
  macOS / Apple-Silicon only (relies on Handy's model + Homebrew whisper-cpp).
---

# Local audio transcription (Handy's Whisper model)

Transcribe any audio/video file to text **on-device** by pointing
[whisper.cpp](https://github.com/ggml-org/whisper.cpp) at the Whisper model the
[Handy](https://handy.computer) dictation app already downloaded. Nothing leaves
the machine; no API key.

## Why this is Mac-specific (it "won't work everywhere")

- The model is **borrowed from Handy.app**, which only runs on this Mac. The file
  lives at `~/Library/Application Support/com.pais.handy/models/`.
- `whisper-cli` is the Homebrew `whisper-cpp` build, compiled with **Metal** for
  Apple-Silicon GPU acceleration — not present on a generic box.

So this is a personal-machine recipe, not a portable pipeline. On another machine
you'd download a model yourself and skip the Handy bits.

## One-time setup

```sh
brew install whisper-cpp ffmpeg
```

The model comes from Handy: open **Handy.app → settings → download a model**
(this skill assumes `ggml-large-v3-q5_0.bin`, ~1 GB, Handy's "large" option).
Confirm it's there:

```sh
ls -la ~/Library/Application\ Support/com.pais.handy/models/
```

## Transcribe (the easy way)

Use the helper script next to this file. It converts the input to the 16 kHz
mono WAV whisper.cpp needs and runs the model:

```sh
~/.claude/skills/transcribe/transcribe.sh recording.m4a          # auto-detect language
~/.claude/skills/transcribe/transcribe.sh -l nl interview.mp3    # force Dutch
~/.claude/skills/transcribe/transcribe.sh -l en -o ./out a.wav b.wav
```

It prints the path of each `.txt` transcript (written next to the input by
default, or into `-o OUTDIR`). Override the model with `HANDY_MODEL=/path/...`.

## Transcribe (manual, if you need control)

```sh
MODEL="$HOME/Library/Application Support/com.pais.handy/models/ggml-large-v3-q5_0.bin"

# 1. whisper.cpp only reads 16 kHz mono PCM WAV — convert first.
ffmpeg -i recording.m4a -ar 16000 -ac 1 -c:a pcm_s16le recording.wav

# 2. Transcribe. -l auto detects language; set -l nl / -l en to pin it.
whisper-cli -m "$MODEL" -f recording.wav -l nl -otxt -of recording
#   -otxt   write recording.txt          -osrt subtitles    -oj JSON w/ timestamps
#   -of     output filename prefix        -np   no progress prints
```

## Notes & gotchas

- **Language:** Handy itself runs with `selected_language: auto`. Auto-detect is
  fine, but pinning the language (`-l nl`) is more reliable for non-English audio.
- **Speed:** large-v3 q5 on Metal runs well faster than real time on Apple
  Silicon; a ~17-min file transcribes in a few minutes. First run pays a ~7 s
  Metal shader-compile tax.
- **No diarization / timestamps in plain text.** Use `-osrt` or `-oj` if you need
  per-segment timing; whisper.cpp does not label speakers.
- **Alternative model:** Handy also ships an NVIDIA **Parakeet** model
  (`models/parakeet-tdt-0.6b-v3-int8/`, English-leaning). `whisper-cpp` installs a
  `parakeet-cli` that can use it — but for Dutch/multilingual, the Whisper model
  above is the better pick.
- **Don't hand-edit this skill in `~/.claude/skills`** — it's a symlink into the
  chezmoi repo (`agents/skills/transcribe/`). Edit the source and `chezmoi apply`.
