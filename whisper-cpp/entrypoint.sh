#!/usr/bin/env bash
# Container entrypoint: download the requested ggml model once (cached in the
# /models volume), then start whisper-server bound to 0.0.0.0.
set -euo pipefail

MODEL="${WHISPER_MODEL:-small}"
PORT="${PORT:-8080}"
THREADS="${THREADS:-0}"
MODELS_DIR="${MODELS_DIR:-/models}"
MODEL_FILE="${MODELS_DIR}/ggml-${MODEL}.bin"
MODEL_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-${MODEL}.bin"

mkdir -p "${MODELS_DIR}"

if [ ! -f "${MODEL_FILE}" ]; then
    echo "[entrypoint] model ggml-${MODEL}.bin not cached — downloading from ${MODEL_URL}"
    curl -fL --retry 3 --retry-delay 2 -C - -o "${MODEL_FILE}.part" "${MODEL_URL}"
    mv "${MODEL_FILE}.part" "${MODEL_FILE}"
    echo "[entrypoint] download complete: $(du -h "${MODEL_FILE}" | cut -f1)"
else
    echo "[entrypoint] using cached model ${MODEL_FILE}"
fi

if [ "${THREADS}" = "0" ]; then
    THREADS="$(nproc)"
fi

echo "[entrypoint] starting whisper-server  model=${MODEL}  port=${PORT}  threads=${THREADS}"
# --convert: server transcodes any input (mp3/m4a/ogg/...) to 16 kHz WAV via ffmpeg.
# shellcheck disable=SC2086
exec whisper-server \
    -m "${MODEL_FILE}" \
    --host 0.0.0.0 \
    --port "${PORT}" \
    -t "${THREADS}" \
    --convert \
    ${WHISPER_EXTRA_ARGS:-}
