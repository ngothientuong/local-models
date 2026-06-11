# Calling the server — all the ways

The server (container **and** native Mac build — identical API) listens on `http://127.0.0.1:8080`
by default. One endpoint does the work:

## `POST /inference` — transcribe one audio file

Multipart form fields:

| Field | Values | Default | Notes |
|---|---|---|---|
| `file` | the audio file | *(required)* | mp3, wav, m4a, flac, ogg, aac, mp4… (server converts via ffmpeg) |
| `response_format` | `text` `json` `verbose_json` `srt` `vtt` | `json` | `text` = plain transcript, `srt`/`vtt` = subtitles with timestamps |
| `language` | `fr`, `en`, `es`, … or `auto` | `en` | **set this** — `fr` for French, or `auto` to detect |
| `temperature` | `0.0`–`1.0` | `0.0` | keep `0.0` for deterministic transcripts |
| `translate` | `true`/`false` | `false` | `true` = translate to English instead of transcribing |

### curl (macOS / Linux / WSL2)

```bash
# plain text transcript
curl -fsS http://127.0.0.1:8080/inference \
  -F file=@lesson1.mp3 -F response_format=text -F language=fr -o lesson1.txt

# subtitles with timestamps
curl -fsS http://127.0.0.1:8080/inference \
  -F file=@lesson1.mp3 -F response_format=srt -F language=fr -o lesson1.srt
```

### Helper scripts (this repo)

```bash
./scripts/transcribe.sh        lesson1.mp3 lesson1.txt --lang fr            # one file
./scripts/transcribe-batch.sh  ./audio     ./transcripts --lang fr          # whole folder
# extra knobs: --url http://other-host:9090   --format srt|vtt|json|text
```

### Windows PowerShell (calling a server running in WSL2/Docker)

```powershell
curl.exe -fsS http://localhost:8080/inference `
  -F "file=@C:\Users\YOU\Downloads\lesson1.mp3" `
  -F "response_format=text" -F "language=fr" -o C:\Users\YOU\Downloads\lesson1.txt
```

### Python

```python
import requests

with open("lesson1.mp3", "rb") as f:
    r = requests.post(
        "http://127.0.0.1:8080/inference",
        files={"file": f},
        data={"response_format": "text", "language": "fr", "temperature": "0.0"},
        timeout=7200,
    )
r.raise_for_status()
open("lesson1.txt", "w", encoding="utf-8").write(r.text)
```

## Common errors

| Error | Meaning / fix |
|---|---|
| `curl: (7) Failed to connect` | Server not running — start it (`./run.sh` or `docker start whisper-server`) |
| `curl: (22) ... 500` | Usually unreadable/corrupt audio — try `ffmpeg -i in.xyz out.wav` first |
| Empty/garbage transcript | Wrong `language` — set `language=fr` (default is `en`!) or `auto` |
| Very long request just hangs | Big file + small CPU — normal; the scripts allow up to 2 h per file |
