#!/usr/bin/env bash
# transcribe.sh — send one audio file to a running whisper-cpp server and write
# the transcript to a text file.
#
# Usage:
#   ./transcribe.sh <audio-file> <output-file> [--url http://127.0.0.1:8080] [--lang fr|en|auto] [--format text|srt|vtt|json]
set -euo pipefail

[ $# -ge 2 ] || { echo "usage: $0 <audio-file> <output-file> [--url URL] [--lang LANG] [--format FMT]" >&2; exit 1; }
AUDIO="$1"; OUT="$2"; shift 2
URL="http://127.0.0.1:8080"
LANG_OPT="auto"
FORMAT="text"
while [ $# -gt 0 ]; do
    case "$1" in
        --url)    URL="$2"; shift 2 ;;
        --lang)   LANG_OPT="$2"; shift 2 ;;
        --format) FORMAT="$2"; shift 2 ;;
        *) echo "unknown arg: $1" >&2; exit 1 ;;
    esac
done

[ -f "$AUDIO" ] || { echo "audio file not found: $AUDIO" >&2; exit 1; }
mkdir -p "$(dirname "$OUT")"

curl -fsS --max-time 7200 "${URL%/}/inference" \
    -F "file=@${AUDIO}" \
    -F "response_format=${FORMAT}" \
    -F "language=${LANG_OPT}" \
    -F "temperature=0.0" \
    -o "$OUT"

echo "transcript written: $OUT ($(wc -c <"$OUT" | tr -d ' ') bytes)"
