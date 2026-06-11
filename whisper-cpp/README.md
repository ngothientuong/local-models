# whisper-cpp — local speech-to-text server

A tiny, self-hosted **speech-to-text HTTP API** built on [whisper.cpp](https://github.com/ggml-org/whisper.cpp)
(OpenAI Whisper models, pinned at `v1.8.6`). Point it at any audio file (mp3, wav, m4a, ogg, …) and it
returns the transcript as plain text, SRT, VTT, or JSON.

It runs **fully offline on your own machine** — no cloud API, no per-minute billing, audio never leaves your computer.

## Two ways to run it

| Mode | Hardware | How | Speed |
|---|---|---|---|
| **Mac GPU (default)** | Apple Silicon (M1/M2/M3/M4), Metal | `./run.sh` — builds and serves natively | ~10–20× realtime with `large-v3-turbo` |
| **CPU container (option)** | Anything with Docker — Windows WSL2, Ubuntu, macOS, amd64 or arm64 | `./run.sh --cpu` or `docker run …` | ~0.5–3× realtime depending on model + CPU |

> **Why isn't the GPU mode inside Docker?** Docker on macOS runs containers in a Linux VM that has
> no access to the Apple Metal GPU. So the GPU path runs the *same server, same API* natively on
> macOS, while the Docker image covers every CPU platform (this is the honest version of
> "image defaults to Mac GPU": one front door, `run.sh`, defaults to the GPU server on a Mac and
> falls back to the CPU container everywhere else).

## Quickstart

### Mac (Apple GPU — default)

```bash
git clone -b develop https://github.com/ngothientuong/local-models.git
cd local-models/whisper-cpp
./run.sh --model large-v3-turbo        # first run: compiles + downloads model (~5 min)
```

### Any machine with Docker (CPU)

```bash
# Public image — no login required:
docker run -d --name whisper-server -p 8080:8080 \
  -v whisper-models:/models \
  -e WHISPER_MODEL=small \
  ghcr.io/ngothientuong/whisper-cpp-server:latest
```

Also mirrored (authenticated) at `tngomgmtacr.azurecr.io/local-models/whisper-cpp-server:latest`.

### Transcribe something

```bash
./scripts/transcribe.sh  /path/to/audio.mp3  /path/to/transcript.txt --lang fr
./scripts/transcribe-batch.sh  /path/to/audio-folder  /path/to/transcripts --lang fr
```

Or raw curl:

```bash
curl -fsS http://127.0.0.1:8080/inference \
  -F file=@audio.mp3 -F response_format=text -F language=auto -o transcript.txt
```

## Choosing a model

Set with `-e WHISPER_MODEL=…` (Docker) or `--model …` (run scripts). Models download automatically
on first start and are cached (Docker volume `whisper-models` / `~/.cache/whisper-models`).

| Model | Download | RAM needed | Quality | Good for |
|---|---|---|---|---|
| `tiny` | 75 MB | ~0.4 GB | basic | smoke tests |
| `base` | 142 MB | ~0.6 GB | okay | quick drafts |
| `small` *(default)* | 466 MB | ~1.2 GB | good | CPU laptops, WSL2 |
| `medium` | 1.5 GB | ~2.8 GB | very good | strong CPUs |
| `large-v3` | 2.9 GB | ~4.5 GB | best | GPU |
| `large-v3-turbo` | 1.6 GB | ~2.5 GB | near-best, much faster | **recommended on Mac GPU** |

English-only variants (`tiny.en`, `base.en`, `small.en`, `medium.en`) and quantized variants
(e.g. `small-q5_1`, `large-v3-turbo-q5_0` — smaller download/RAM, slight quality cost) also work.

## Step-by-step beginner guides

- **[docs/DEPLOY_WSL2_CPU.md](docs/DEPLOY_WSL2_CPU.md)** — Windows + WSL2 + Docker, from a blank PC to a transcript
- **[docs/DEPLOY_MAC_GPU.md](docs/DEPLOY_MAC_GPU.md)** — macOS Apple Silicon GPU, from a blank Mac to a transcript
- **[docs/API_CALLS.md](docs/API_CALLS.md)** — every way to call the server (curl, scripts, PowerShell, Python)

## Files in this folder

| File | Purpose |
|---|---|
| `Dockerfile` | Multi-arch (amd64+arm64) CPU image build |
| `entrypoint.sh` | Container boot: model auto-download + server start |
| `run.sh` | Front door — defaults to Mac GPU, `--cpu` for Docker |
| `run-mac-gpu.sh` | Native Metal build + serve (also `--stop`) |
| `scripts/transcribe.sh` | One file → one transcript |
| `scripts/transcribe-batch.sh` | Folder of audio → folder of transcripts |
