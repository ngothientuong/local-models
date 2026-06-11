#!/usr/bin/env bash
# run.sh — front door for the whisper-cpp speech-to-text server.
#
# Default mode = Mac GPU (native Metal) when on Apple Silicon macOS.
# Option       = --cpu : run the multi-arch Docker image (works on WSL2/Ubuntu/Mac, CPU only).
#
#   ./run.sh                       # Mac: native Metal GPU server on :8080
#   ./run.sh --model large-v3-turbo
#   ./run.sh --cpu                 # Docker CPU container (any OS with Docker)
#   ./run.sh --cpu --model base
set -euo pipefail

IMAGE="${WHISPER_IMAGE:-ghcr.io/ngothientuong/whisper-cpp-server:latest}"
MODE="auto"
MODEL="small"
PORT=8080
ARGS=()

while [ $# -gt 0 ]; do
    case "$1" in
        --cpu)   MODE="cpu"; shift ;;
        --gpu)   MODE="gpu"; shift ;;
        --model) MODEL="$2"; shift 2 ;;
        --port)  PORT="$2"; shift 2 ;;
        *) ARGS+=("$1"); shift ;;
    esac
done

if [ "$MODE" = "auto" ]; then
    if [ "$(uname -s)" = "Darwin" ] && [ "$(uname -m)" = "arm64" ]; then
        MODE="gpu"
    else
        MODE="cpu"
    fi
fi

if [ "$MODE" = "gpu" ]; then
    exec "$(dirname "$0")/run-mac-gpu.sh" --model "$MODEL" --port "$PORT" ${ARGS[@]+"${ARGS[@]}"}
fi

command -v docker >/dev/null 2>&1 || { echo "docker not found — install Docker first (see docs/DEPLOY_WSL2_CPU.md)" >&2; exit 1; }
docker rm -f whisper-server >/dev/null 2>&1 || true
docker run -d --name whisper-server \
    -p "${PORT}:8080" \
    -v whisper-models:/models \
    -e WHISPER_MODEL="${MODEL}" \
    "${IMAGE}"
echo "whisper-server (CPU container) starting on http://127.0.0.1:${PORT}"
echo "first start downloads the model — watch progress with:  docker logs -f whisper-server"
