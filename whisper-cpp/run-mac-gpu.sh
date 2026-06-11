#!/usr/bin/env bash
# run-mac-gpu.sh — build (once) and run whisper-server natively on macOS with
# full Apple Metal GPU acceleration. Docker on macOS cannot reach the GPU, so
# the GPU path runs on the host. Same HTTP API as the container.
#
# Usage:
#   ./run-mac-gpu.sh                          # build if needed, serve 'small' on :8080
#   ./run-mac-gpu.sh --model large-v3-turbo   # pick a model
#   ./run-mac-gpu.sh --port 9090              # pick a port
#   ./run-mac-gpu.sh --build-only             # just build + download, don't serve
#   ./run-mac-gpu.sh --foreground             # serve in the foreground (default: background)
set -euo pipefail

WHISPER_VERSION="${WHISPER_VERSION:-v1.8.6}"
INSTALL_DIR="${WHISPER_INSTALL_DIR:-$HOME/.local/share/whisper-cpp}"
MODELS_DIR="${WHISPER_MODELS_DIR:-$HOME/.cache/whisper-models}"
MODEL="small"
PORT=8080
BUILD_ONLY=0
FOREGROUND=0
LOG_FILE="${TMPDIR:-/tmp}/whisper-server.log"
PID_FILE="${TMPDIR:-/tmp}/whisper-server.pid"

while [ $# -gt 0 ]; do
    case "$1" in
        --model)      MODEL="$2"; shift 2 ;;
        --port)       PORT="$2"; shift 2 ;;
        --build-only) BUILD_ONLY=1; shift ;;
        --foreground) FOREGROUND=1; shift ;;
        --stop)
            if [ -f "$PID_FILE" ] && kill "$(cat "$PID_FILE")" 2>/dev/null; then
                echo "stopped whisper-server (pid $(cat "$PID_FILE"))"; rm -f "$PID_FILE"
            else
                pkill -f 'whisper-server .*--port' 2>/dev/null && echo "stopped whisper-server" || echo "no whisper-server running"
            fi
            exit 0 ;;
        -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "unknown arg: $1" >&2; exit 1 ;;
    esac
done

if [ "$(uname -s)" != "Darwin" ]; then
    echo "This script is for macOS. On Linux/WSL2 use the Docker image (see docs/DEPLOY_WSL2_CPU.md)." >&2
    exit 1
fi

# --- prerequisites -----------------------------------------------------------
if ! xcode-select -p >/dev/null 2>&1; then
    echo "Apple Command Line Tools missing. Run:  xcode-select --install   then re-run this script." >&2
    exit 1
fi
if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew missing. Install from https://brew.sh then re-run." >&2
    exit 1
fi
for pkg in cmake ffmpeg; do
    command -v "$pkg" >/dev/null 2>&1 || brew install "$pkg"
done

# --- build (once per version) ------------------------------------------------
SRC_DIR="${INSTALL_DIR}/whisper.cpp-${WHISPER_VERSION}"
SERVER_BIN="${SRC_DIR}/build/bin/whisper-server"
if [ ! -x "$SERVER_BIN" ]; then
    echo "[build] cloning whisper.cpp ${WHISPER_VERSION} ..."
    mkdir -p "$INSTALL_DIR"
    rm -rf "$SRC_DIR"
    git clone --depth 1 --branch "$WHISPER_VERSION" https://github.com/ggml-org/whisper.cpp "$SRC_DIR"
    echo "[build] compiling with Metal (Apple GPU) support ..."
    cmake -S "$SRC_DIR" -B "$SRC_DIR/build" -DCMAKE_BUILD_TYPE=Release
    cmake --build "$SRC_DIR/build" --config Release -j"$(sysctl -n hw.ncpu)" --target whisper-server
fi
echo "[build] whisper-server ready: $SERVER_BIN"

# --- model -------------------------------------------------------------------
mkdir -p "$MODELS_DIR"
MODEL_FILE="${MODELS_DIR}/ggml-${MODEL}.bin"
if [ ! -f "$MODEL_FILE" ]; then
    echo "[model] downloading ggml-${MODEL}.bin ..."
    curl -fL --retry 3 -C - -o "${MODEL_FILE}.part" \
        "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-${MODEL}.bin"
    mv "${MODEL_FILE}.part" "$MODEL_FILE"
fi
echo "[model] using $MODEL_FILE"

[ "$BUILD_ONLY" = "1" ] && { echo "[done] build-only requested."; exit 0; }

# --- serve -------------------------------------------------------------------
# Run from a stable runtime dir: --convert writes temp WAVs relative to CWD, and
# a CWD deleted later (e.g. by a git checkout) breaks every conversion with
# "getcwd: No such file or directory".
RUNTIME_DIR="${INSTALL_DIR}/run"
mkdir -p "$RUNTIME_DIR"
cd "$RUNTIME_DIR"
CMD=("$SERVER_BIN" -m "$MODEL_FILE" --host 127.0.0.1 --port "$PORT" -t "$(sysctl -n hw.ncpu)" --convert)
if [ "$FOREGROUND" = "1" ]; then
    exec "${CMD[@]}"
else
    nohup "${CMD[@]}" >"$LOG_FILE" 2>&1 &
    echo $! > "$PID_FILE"
    sleep 2
    if kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "[serve] whisper-server running on http://127.0.0.1:${PORT}  (pid $(cat "$PID_FILE"), log: $LOG_FILE)"
        echo "[serve] stop with:  $0 --stop"
    else
        echo "[serve] FAILED to start — last log lines:" >&2; tail -20 "$LOG_FILE" >&2; exit 1
    fi
fi
