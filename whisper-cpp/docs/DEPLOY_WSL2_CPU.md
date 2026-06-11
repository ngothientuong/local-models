# Deploy on Windows (WSL2, CPU) — beginner guide, tip to toe

Goal: starting from a normal Windows 10/11 PC, end with a running local speech-to-text
server and a transcript of your own audio file. Everything runs on your machine; no accounts,
no API keys, no GPU needed.

**Time:** ~20 minutes (mostly downloads). **Disk:** ~3 GB free.

---

## Step 1 — Install WSL2 (Windows Subsystem for Linux)

1. Click **Start**, type `powershell`, right-click **Windows PowerShell** → **Run as administrator**.
2. Run:
   ```powershell
   wsl --install
   ```
   This installs WSL2 with Ubuntu by default.
3. **Reboot** when asked.
4. After reboot, an Ubuntu window opens and asks you to create a **username and password**
   (this is for Linux only — pick anything you'll remember).

Already have WSL? Just make sure it's WSL **2**:
```powershell
wsl --status
wsl --set-default-version 2
```

## Step 2 — Install Docker

Two options — pick **A** if you like clicking, **B** if you prefer staying in the terminal.

### Option A (easiest): Docker Desktop

1. Download from <https://www.docker.com/products/docker-desktop/> and install (defaults are fine —
   keep **"Use WSL 2 based engine"** checked).
2. Start Docker Desktop, wait for the whale icon to say "running".
3. In Docker Desktop **Settings → Resources → WSL integration**, make sure your Ubuntu distro is enabled.

### Option B: Docker straight inside Ubuntu/WSL2 (no Docker Desktop)

Open the **Ubuntu** app and run:

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin
sudo usermod -aG docker $USER
```

Close the Ubuntu window, open it again (so the group change applies), then check:

```bash
docker run --rm hello-world
```

## Step 3 — Start the speech-to-text server

In the **Ubuntu** terminal:

```bash
docker run -d --name whisper-server -p 8080:8080 \
  -v whisper-models:/models \
  -e WHISPER_MODEL=small \
  ghcr.io/ngothientuong/whisper-cpp-server:latest
```

Notes:
- The image is **public** — no `docker login` needed.
- `WHISPER_MODEL=small` is a good CPU default. Low-RAM machine? Use `base`. Strong machine? `medium`.
- **First start downloads the model** (~466 MB for `small`). Watch it:
  ```bash
  docker logs -f whisper-server
  ```
  Wait until you see `whisper server listening` / the download finish, then press `Ctrl+C` (the server keeps running).

## Step 4 — Transcribe your audio file

Your Windows drives are visible inside WSL2 under `/mnt/c/...`. Example with a file in your Windows Downloads folder:

```bash
curl -fsS http://127.0.0.1:8080/inference \
  -F "file=@/mnt/c/Users/YOURNAME/Downloads/lesson1.mp3" \
  -F "response_format=text" \
  -F "language=auto" \
  -o /mnt/c/Users/YOURNAME/Downloads/lesson1.txt
```

Open `lesson1.txt` in Notepad — that's your transcript. For French audio, set `-F "language=fr"`.

Helper scripts (single file / whole folder) live in this repo:

```bash
git clone -b develop https://github.com/ngothientuong/local-models.git
cd local-models/whisper-cpp
./scripts/transcribe.sh /mnt/c/Users/YOURNAME/Downloads/lesson1.mp3 ./lesson1.txt --lang fr
./scripts/transcribe-batch.sh /mnt/c/Users/YOURNAME/Downloads/audio-folder ./transcripts --lang fr
```

## Step 5 — Daily driving

```bash
docker stop whisper-server      # stop
docker start whisper-server     # start again (model already cached — boots in seconds)
docker rm -f whisper-server     # remove completely
docker run ... -e WHISPER_MODEL=medium ...   # switch model (re-run Step 3 with a new value)
```

## Troubleshooting

| Symptom | Fix |
|---|---|
| `docker: command not found` | Docker Desktop not running, or WSL integration off (Option A) / re-open terminal after `usermod` (Option B) |
| First request very slow | Model still downloading — `docker logs -f whisper-server` |
| `port is already allocated` | Something else uses 8080 → use `-p 9090:8080` and call `http://127.0.0.1:9090` |
| Container exits immediately | `docker logs whisper-server` — most common: out of RAM for the chosen model → pick a smaller one |
| Very old CPU (pre-2013, no AVX2) crashes | Rebuild the image with `-DGGML_AVX2=OFF` (see Dockerfile) — rare |
| Calling from Windows apps | `http://localhost:8080` works from Windows too — WSL2 forwards localhost automatically |
