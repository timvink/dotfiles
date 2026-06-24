#!/bin/sh
# Local, offline speech-to-text on macOS using the Whisper large-v3 model that
# the Handy app (https://handy.computer) already downloaded. No cloud, no API key.
#
# Usage:
#   transcribe.sh [-l LANG] [-o OUTDIR] FILE [FILE ...]
#
#   -l LANG    language code (nl, en, de, ...). Default: auto-detect.
#   -o OUTDIR  write .txt transcripts here. Default: alongside each input file.
#   -h         show this help.
#
# Each input (any ffmpeg-readable audio/video) is converted to 16 kHz mono WAV
# in a temp dir, then transcribed with whisper-cli. Prints each transcript path.
#
# Requires (macOS / Apple Silicon): Handy.app's downloaded model,
# `brew install whisper-cpp`, and ffmpeg. See SKILL.md for the full story.

set -eu

MODEL="${HANDY_MODEL:-$HOME/Library/Application Support/com.pais.handy/models/ggml-large-v3-q5_0.bin}"
LANG_OPT="auto"
OUTDIR=""

while getopts "l:o:h" opt; do
	case "$opt" in
		l) LANG_OPT="$OPTARG" ;;
		o) OUTDIR="$OPTARG" ;;
		h) grep '^#' "$0" | sed '1d;s/^#\{1,\} \{0,1\}//'; exit 0 ;;
		*) echo "transcribe.sh: see -h for usage" >&2; exit 2 ;;
	esac
done
shift $((OPTIND - 1))

[ "$#" -ge 1 ] || { echo "transcribe.sh: no input files (try -h)" >&2; exit 2; }

command -v whisper-cli >/dev/null 2>&1 || { echo "transcribe.sh: whisper-cli not found -> brew install whisper-cpp" >&2; exit 1; }
command -v ffmpeg >/dev/null 2>&1 || { echo "transcribe.sh: ffmpeg not found -> brew install ffmpeg" >&2; exit 1; }
[ -f "$MODEL" ] || { echo "transcribe.sh: Handy model missing at $MODEL" >&2; echo "  Open Handy.app and download a Whisper model, or set HANDY_MODEL." >&2; exit 1; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

for in in "$@"; do
	[ -f "$in" ] || { echo "transcribe.sh: skip (not a file): $in" >&2; continue; }
	stem="$(basename "$in")"; stem="${stem%.*}"
	wav="$tmp/$stem.wav"
	ffmpeg -y -loglevel error -i "$in" -ar 16000 -ac 1 -c:a pcm_s16le "$wav"

	if [ -n "$OUTDIR" ]; then mkdir -p "$OUTDIR"; out="$OUTDIR/$stem"; else out="$(dirname "$in")/$stem"; fi

	# -otxt writes "$out.txt"; -np keeps stdout quiet so we only print the path.
	whisper-cli -m "$MODEL" -f "$wav" -l "$LANG_OPT" -otxt -of "$out" -np
	echo "$out.txt"
done
