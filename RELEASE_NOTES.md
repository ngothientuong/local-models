# Release Notes — local-models

## 0.1.1 — 2026-06-11

- **fix(whisper-cpp/run-mac-gpu.sh)**: start `whisper-server` from a stable runtime dir
  (`~/.local/share/whisper-cpp/run`). Previously the server inherited the caller's CWD;
  `--convert` writes its temp WAV relative to CWD, so a later deletion of that directory
  (e.g. a `git checkout` removing the folder the server was started from) broke every
  conversion with `getcwd: No such file or directory` / HTTP 500 "FFmpeg conversion failed".
  Container path unaffected (stable CWD `/`); no image rebuild required.
- Verified post-fix: 65-file DELF batch re-run — 0 failures, ~63× realtime warm, 65/65
  outputs byte-identical to the 0.1.0 corpus.

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
