# syntax=docker.io/docker/dockerfile:1@sha256:865e5dd094beca432e8c0a1d5e1c465db5f998dca4e439981029b3b81fb39ed5

# https://hub.docker.com/r/linuxserver/ffmpeg
# https://hub.docker.com/r/jrottenberg/ffmpeg/tags
# https://github.com/linuxserver/docker-ffmpeg

FROM --platform=$BUILDPLATFORM docker.io/linuxserver/ffmpeg:8.0-cli-ls45@sha256:053970615c3b200898e34ece30d4064a071f74aefc694d7782ffcccd761d2a65 AS tool

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
# https://trac.ffmpeg.org/wiki/HWAccelIntro
RUN \
    # ffmpeg -i ../input/"$INPUT" -c:v libx265 -crf 22 -preset medium -c:a ac3 -c:s copy ./"$INPUT"
    ffmpeg -i ../input/"$INPUT" -c:v hevc_videotoolbox -q:v 65 -c:a ac3 -c:s copy ./"$INPUT"

# Run with -q:v 65. The value should be 1-100, the higher the number, the better the quality. 65 seems to be acceptable.

# https://trac.ffmpeg.org/wiki/CompilationGuide/macOS


FROM scratch
COPY --from=product /app/outputs/* /

## ARG INPUT: path to video file in input/ directory
## Usage:
# stat input/my-video.mkv && DOCKER_BUILDKIT=1 docker build -o=outputs/ --build-arg INPUT=my-video.mkv input/ -f Dockerfile && ( ls -1 outputs/ && rm outputs/my-video.mkv )
# my-video.mkv
