# syntax=docker/dockerfile:1
# whisper-cpp-server — multi-arch (linux/amd64 + linux/arm64) CPU speech-to-text HTTP API.
# GPU note: Docker containers cannot access the Apple Metal GPU. For Mac GPU inference,
# run the server natively via run-mac-gpu.sh (same API, same model files).

ARG WHISPER_VERSION=v1.8.6

FROM debian:bookworm-slim AS build
ARG WHISPER_VERSION
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential cmake git ca-certificates \
    && rm -rf /var/lib/apt/lists/*
RUN git clone --depth 1 --branch ${WHISPER_VERSION} https://github.com/ggml-org/whisper.cpp /src
# GGML_NATIVE=OFF -> portable baseline ISA (no -march=native), safe for any host of the same arch.
RUN cmake -S /src -B /build \
        -DCMAKE_BUILD_TYPE=Release \
        -DGGML_NATIVE=OFF \
        -DBUILD_SHARED_LIBS=OFF \
        -DWHISPER_BUILD_TESTS=OFF \
        -DWHISPER_BUILD_EXAMPLES=ON \
    && cmake --build /build --config Release -j"$(nproc)" --target whisper-server

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
        ffmpeg curl ca-certificates libgomp1 \
    && rm -rf /var/lib/apt/lists/*
COPY --from=build /build/bin/whisper-server /usr/local/bin/whisper-server
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh && mkdir -p /models

ENV WHISPER_MODEL=small \
    PORT=8080 \
    THREADS=0 \
    MODELS_DIR=/models

EXPOSE 8080
VOLUME ["/models"]

# start-period generous: first boot downloads the model file into /models.
HEALTHCHECK --interval=30s --timeout=5s --start-period=300s --retries=5 \
    CMD curl -s -o /dev/null "http://127.0.0.1:${PORT}/" || exit 1

LABEL org.opencontainers.image.source="https://github.com/ngothientuong/local-models" \
      org.opencontainers.image.description="whisper.cpp speech-to-text HTTP API server (CPU multi-arch; Mac GPU served natively)" \
      org.opencontainers.image.licenses="MIT"

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
