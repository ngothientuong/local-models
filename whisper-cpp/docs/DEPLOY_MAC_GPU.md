# Deploy on macOS (Apple Silicon GPU) — beginner guide, tip to toe

Goal: starting from a Mac with an M-series chip (M1/M2/M3/M4), end with a speech-to-text server
that uses the **Apple GPU (Metal)** and a transcript of your own audio file.

**Why native instead of Docker here?** Docker on macOS runs containers inside a Linux VM that
cannot see the Apple GPU. Running the server natively gives you the GPU — typically **10–20× realtime**
with the `large-v3-turbo` model. (If you'd rather use Docker on your Mac, that works too — CPU only —
see the WSL2/CPU guide, the same `docker run` command applies.)

**Time:** ~10 minutes first run. **Disk:** ~2.5 GB (code + model).

---

## Step 1 — One-time prerequisites

Open **Terminal** (Cmd+Space, type "Terminal").

1. Apple Command Line Tools (compiler):
   ```bash
   xcode-select --install
   ```
   Click **Install** in the popup. Already installed? It says so — fine.

2. Homebrew (the Mac package manager) — skip if `brew --version` already works:
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

## Step 2 — Get this repo and start the server

```bash
git clone -b develop https://github.com/ngothientuong/local-models.git
cd local-models/whisper-cpp
./run.sh --model large-v3-turbo
```

That single command (via `run-mac-gpu.sh`):
1. installs `cmake` + `ffmpeg` via Homebrew if missing,
2. downloads + compiles whisper.cpp `v1.8.6` with Metal support (~2–3 min, one time),
3. downloads the `ggml-large-v3-turbo.bin` model (~1.6 GB, one time, cached in `~/.cache/whisper-models`),
4. starts the server in the background on `http://127.0.0.1:8080`.

Low on RAM or want faster startup? Use `--model small` (466 MB) — still very good.

**Verify the GPU is actually used:**
```bash
grep -m1 'Metal' "${TMPDIR:-/tmp}/whisper-server.log"
```
You should see a `ggml_metal_init` / "Metal" line naming your Apple GPU.

## Step 3 — Transcribe your audio file

```bash
./scripts/transcribe.sh ~/Downloads/lesson1.mp3 ~/Downloads/lesson1.txt --lang fr
```

- `--lang fr` for French, `--lang auto` to auto-detect, `--format srt` for subtitles.
- A whole folder at once:
  ```bash
  ./scripts/transcribe-batch.sh ~/Downloads/audio-folder ~/Downloads/transcripts --lang fr
  ```
- Raw curl, if you prefer:
  ```bash
  curl -fsS http://127.0.0.1:8080/inference \
    -F file=@$HOME/Downloads/lesson1.mp3 -F response_format=text -F language=fr \
    -o ~/Downloads/lesson1.txt
  ```

## Step 4 — Daily driving

```bash
./run-mac-gpu.sh --stop                     # stop the server
./run.sh --model large-v3-turbo             # start again (everything cached — seconds)
./run.sh --model small --port 9090          # different model / port
tail -f "${TMPDIR:-/tmp}/whisper-server.log"  # watch the server log
```

## Troubleshooting

| Symptom | Fix |
|---|---|
| `xcode-select: error` during build | Run `xcode-select --install`, finish the popup, re-run `./run.sh` |
| `brew: command not found` | Install Homebrew (Step 1.2), then close + reopen Terminal |
| Port 8080 busy | `./run.sh --port 9090` and call `http://127.0.0.1:9090` |
| Slow transcription | You're probably on the `medium`/`large-v3` model — switch to `large-v3-turbo`, or check the Metal line in the log (Step 2) |
| Out-of-memory kill on 8 GB Macs | Use `--model small` or quantized `--model large-v3-turbo-q5_0` |
| Want it fully inside Docker anyway | Works, CPU-only: same `docker run` as the WSL2 guide |
