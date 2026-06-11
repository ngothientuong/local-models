# local-models

Self-hosted local AI model servers — one folder per model, each shipping a multi-arch Docker
image, native-GPU run scripts where applicable, client scripts, and beginner deploy docs.

| Model | Task | Folder | Image (public, no login) |
|---|---|---|---|
| whisper.cpp `v1.8.6` | speech-to-text (audio → transcript) | [`whisper-cpp/`](whisper-cpp/) | `ghcr.io/ngothientuong/whisper-cpp-server:latest` |

Images are also mirrored to Azure Container Registry: `tngomgmtacr.azurecr.io/local-models/<name>:<tag>` (authenticated).

## Conventions

- Default branch: `develop`.
- Each model folder is self-contained: `Dockerfile`, `run.sh` (front door), `scripts/` (clients),
  `docs/` (beginner tip-to-toe guides for Windows WSL2 CPU and macOS GPU).
- Images are multi-arch (`linux/amd64` + `linux/arm64`), CPU-portable; GPU paths run natively
  where containers can't reach the GPU (e.g. Apple Metal).
- Models are never baked into images — downloaded on first start and cached in a volume.

## Quickstart (speech-to-text)

```bash
docker run -d --name whisper-server -p 8080:8080 \
  -v whisper-models:/models -e WHISPER_MODEL=small \
  ghcr.io/ngothientuong/whisper-cpp-server:latest

curl -fsS http://127.0.0.1:8080/inference \
  -F file=@audio.mp3 -F response_format=text -F language=auto -o transcript.txt
```

Full beginner walk-throughs: [whisper-cpp/docs/](whisper-cpp/docs/).
