# Release Notes — local-models

## 0.1.0 — 2026-06-11

Initial release.

- **whisper-cpp** (`whisper-cpp/`): speech-to-text HTTP API server on whisper.cpp `v1.8.6`.
  - Multi-arch CPU Docker image (`linux/amd64` + `linux/arm64`), model auto-download with
    volume caching, ffmpeg input conversion (`--convert`), healthcheck.
  - Native macOS Apple-GPU (Metal) path: `run-mac-gpu.sh`; unified front door `run.sh`
    (defaults to Mac GPU on Apple Silicon, `--cpu` runs the container).
  - Client scripts: `scripts/transcribe.sh` (single file), `scripts/transcribe-batch.sh` (folder).
  - Beginner docs: Windows WSL2 CPU deploy, macOS GPU deploy, API call reference.
  - Published: `ghcr.io/ngothientuong/whisper-cpp-server:{0.1.0,latest}` (public) and
    `tngomgmtacr.azurecr.io/local-models/whisper-cpp-server:{0.1.0,latest}`.
