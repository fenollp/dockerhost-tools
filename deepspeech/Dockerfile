# syntax=docker/dockerfile:1.3@sha256:9e2c9eca7367393aecc68795c671f93466818395a2693498debe831fd67f5e89

ARG VERSION=0.9.3


# Download pre-trained English model files (pbmm, scorer)
# More acoustic models (e.g. experimental Mandarin Chinese) at https://github.com/mozilla/DeepSpeech/releases/tag/v$VERSION

FROM scratch AS pbmm
ARG VERSION
ADD https://github.com/mozilla/DeepSpeech/releases/download/v$VERSION/deepspeech-$VERSION-models.pbmm /models.pbmm

FROM scratch AS scorer
ARG VERSION
ADD https://github.com/mozilla/DeepSpeech/releases/download/v$VERSION/deepspeech-$VERSION-models.scorer /models.scorer


# Create CPU and GPU versions of the tool

FROM --platform=$BUILDPLATFORM python:3-slim@sha256:8402d0ea6e4eaeba7b390dfe522496e365334daaeb05361b24636f2407e10aae AS python-tool
RUN \
    set -ux \
    # https://github.com/moby/buildkit/blob/8f2e691b19969f3bc2737d98054d26f8e7c37619/frontend/dockerfile/docs/syntax.md#example-cache-apt-packages
 && rm -f /etc/apt/apt.conf.d/docker-clean \
 && echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' >/etc/apt/apt.conf.d/keep-cache
RUN \
    --mount=type=cache,target=/var/lib/apt \
    --mount=type=cache,target=/var/cache/apt \
    set -ux \
 && apt update \
 # SoX for audio resampling. See:
 #   Warning: original sample rate (44100) is different than 16000hz. Resampling might produce erratic speech recognition.
 && apt install -y sox

FROM python-tool AS tool-cpu
ARG VERSION
RUN \
    set -ux \
 && pip install --no-cache-dir deepspeech==$VERSION

FROM python-tool AS tool-gpu
ARG VERSION
RUN \
    set -ux \
 && pip install --no-cache-dir deepspeech-gpu==$VERSION


# Inputs

FROM scratch AS data
ARG AUDIO_URL
ADD "$AUDIO_URL" /data


# Run the tool

FROM tool-cpu AS product-cpu
RUN \
    --mount=from=data,source=/data,target=/data \
    --mount=from=pbmm,source=/models.pbmm,target=/models.pbmm \
    --mount=from=scorer,source=/models.scorer,target=/models.scorer \
    set -ux \
 && deepspeech --model /models.pbmm --scorer /models.scorer --audio /data --json --candidate_transcripts 5 >/out

FROM tool-gpu AS product-gpu
RUN \
    --mount=from=data,source=/data,target=/data \
    --mount=from=pbmm,source=/models.pbmm,target=/models.pbmm \
    --mount=from=scorer,source=/models.scorer,target=/models.scorer \
    set -ux \
 && deepspeech --model /models.pbmm --scorer /models.scorer --audio /data --json --candidate_transcripts 5 >/out


# Outputs

FROM scratch AS out-cpu
COPY --from=product-cpu /out /

FROM scratch AS out-gpu
COPY --from=product-gpu /out /


# Default target
FROM out-cpu


## AS out-cpu: CPU-only inference version
## AS out-gpu: GPU-only inference version (CUDA) TODO: install requirements + bridge to nVidia HW.
## ARG VERSION=0.9.3: SemVer of DeepSpeech
## ARG AUDIO_URL: URL of WAV file to run inference on. Is downloaded using Dockerfile's ADD statement.
## Usage:
# DOCKER_BUILDKIT=1 docker build -o=. --build-arg AUDIO_URL=https://www.wavsource.com/snds_2020-10-01_3728627494378403/movies/2001/disconnect_me.wav - <Dockerfile && ( cat out | jq -S --tab '.transcripts[0]' && rm out )
# ```json
# {
#     "confidence": -85.70286560058594,
#     "words": [
#         {
#             "duration": 0.1,
#             "start_time": 0.28,
#             "word": "i"
#         },
#         {
#             "duration": 0.16,
#             "start_time": 0.42,
#             "word": "know"
#         },
#         {
#             "duration": 0.12,
#             "start_time": 0.62,
#             "word": "that"
#         },
#         {
#             "duration": 0.12,
#             "start_time": 0.8,
#             "word": "you"
#         },
#         {
#             "duration": 0.18,
#             "start_time": 0.98,
#             "word": "and"
#         },
#         {
#             "duration": 0.28,
#             "start_time": 1.2,
#             "word": "frank"
#         },
#         {
#             "duration": 0.18,
#             "start_time": 1.56,
#             "word": "were"
#         },
#         {
#             "duration": 0.28,
#             "start_time": 1.78,
#             "word": "planning"
#         },
#         {
#             "duration": 0.12,
#             "start_time": 2.1,
#             "word": "to"
#         },
#         {
#             "duration": 0.56,
#             "start_time": 2.3,
#             "word": "disconnect"
#         },
#         {
#             "duration": 0.6,
#             "start_time": 2.94,
#             "word": "me"
#         },
#         {
#             "duration": 0.1,
#             "start_time": 3.64,
#             "word": "and"
#         },
#         {
#             "duration": 0.1,
#             "start_time": 3.82,
#             "word": "i'm"
#         },
#         {
#             "duration": 0.32,
#             "start_time": 4,
#             "word": "afraid"
#         },
#         {
#             "duration": 0.2,
#             "start_time": 4.38,
#             "word": "that"
#         },
#         {
#             "duration": 0.3,
#             "start_time": 4.62,
#             "word": "something"
#         },
#         {
#             "duration": 0.08,
#             "start_time": 5.04,
#             "word": "i"
#         },
#         {
#             "duration": 0.24,
#             "start_time": 5.18,
#             "word": "cannot"
#         },
#         {
#             "duration": 0.26,
#             "start_time": 5.48,
#             "word": "allow"
#         },
#         {
#             "duration": 0.08,
#             "start_time": 5.8,
#             "word": "to"
#         },
#         {
#             "duration": 0.16,
#             "start_time": 5.94,
#             "word": "have"
#         }
#     ]
# }
# ```
