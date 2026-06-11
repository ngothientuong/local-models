#!/usr/bin/env bash
# transcribe-batch.sh — transcribe every audio file in a folder to .txt files.
#
# Usage:
#   ./transcribe-batch.sh <audio-dir> <output-dir> [--url URL] [--lang fr|en|auto]
set -euo pipefail

[ $# -ge 2 ] || { echo "usage: $0 <audio-dir> <output-dir> [--url URL] [--lang LANG]" >&2; exit 1; }
IN_DIR="$1"; OUT_DIR="$2"; shift 2
URL="http://127.0.0.1:8080"
LANG_OPT="auto"
while [ $# -gt 0 ]; do
    case "$1" in
        --url)  URL="$2"; shift 2 ;;
        --lang) LANG_OPT="$2"; shift 2 ;;
        *) echo "unknown arg: $1" >&2; exit 1 ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$OUT_DIR"
shopt -s nullglob nocaseglob
count=0; failed=0
for f in "$IN_DIR"/*.{mp3,wav,m4a,flac,ogg,aac,wma,mp4}; do
    base="$(basename "$f")"
    out="$OUT_DIR/${base%.*}.txt"
    printf '[%s] %s -> %s\n' "$(date +%H:%M:%S)" "$base" "$out"
    if ! "$SCRIPT_DIR/transcribe.sh" "$f" "$out" --url "$URL" --lang "$LANG_OPT"; then
        echo "  FAILED: $base" >&2; failed=$((failed+1))
    fi
    count=$((count+1))
done
echo "done: $count files processed, $failed failed"
[ "$failed" -eq 0 ]
