---
name: transcribe
description: Transcribe audio or video locally on this Apple Silicon Mac using the existing Handy Whisper model and the bundled helper.
---

# Local transcription

Use `transcribe.sh` beside this file. It converts input to 16 kHz mono WAV and
runs whisper.cpp with Handy's model; audio stays on the machine.

```sh
~/.local/share/chezmoi/agents/skills/transcribe/transcribe.sh recording.m4a
~/.local/share/chezmoi/agents/skills/transcribe/transcribe.sh -l nl interview.mp3
~/.local/share/chezmoi/agents/skills/transcribe/transcribe.sh -l en -o /tmp/transcripts a.wav b.wav
```

The helper prints each transcript's path. Output defaults to beside the input;
use `-o` for a chosen directory. Pin the language when known; otherwise the helper
auto-detects it. Set `HANDY_MODEL` to use a different model file.

The default model is
`~/Library/Application Support/com.pais.handy/models/ggml-large-v3-q5_0.bin`.
Check it exists. Handy downloads it through its settings; `whisper-cpp` and
`ffmpeg` are declared in the chezmoi macOS package script. Route missing persistent
dependencies through that setup rather than installing them ad hoc.

This recipe depends on the local model and Apple Silicon tooling; don't assume
it exists on Linux. Plain text has no timestamps or speaker labels. For segment
timing, use whisper-cli's `-osrt` or `-oj` output options after the same conversion;
these do not provide speaker diarization. Verify the output exists and inspect
its text before reporting the transcript path.
