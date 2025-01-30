# syntax=docker.io/docker/dockerfile:1@sha256:865e5dd094beca432e8c0a1d5e1c465db5f998dca4e439981029b3b81fb39ed5

# https://hub.docker.com/r/linuxserver/ffmpeg
# https://github.com/linuxserver/docker-ffmpeg

FROM --platform=$BUILDPLATFORM docker.io/linuxserver/ffmpeg:6.1.1@sha256:eb164204fc1b3ff22c116cbcaed24a34b8dce9b27c1e7e4628d5afe22acbf7a1 AS tool

# docker buildx build --target=versions --progress=plain  - <./Dockerfile
FROM tool AS versions
RUN \
    set -ux \
 && ffmpeg -version \
 && exit 42 # Force showing logs

FROM tool AS product
WORKDIR /app/input
ARG INPUT
RUN \
    if [ -z "$INPUT" ]; then echo Missing INPUT && exit 2; fi
COPY ./$INPUT .
WORKDIR /app/output
RUN \
    ffmpeg -i ../input/"$INPUT" -c:v libx265 -crf 22 -preset medium -c:a ac3 -c:s copy ./"$INPUT"

FROM scratch
COPY --from=product /app/outputs/* /

## ARG INPUT: path to video file in input/ directory
## Usage:
# stat input/my-video.mkv && DOCKER_BUILDKIT=1 docker build -o=outputs/ --build-arg INPUT=my-video.mkv input/ -f Dockerfile && ( ls -1 outputs/ && rm outputs/my-video.mkv )
# my-video.mkv
