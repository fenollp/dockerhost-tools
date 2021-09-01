# syntax=docker/dockerfile:1.2@sha256:e2a8561e419ab1ba6b2fe6cbdf49fd92b95912df1cf7d313c3e2230a333fdbcc


FROM --platform=$BUILDPLATFORM python:alpine@sha256:fc7de772c6b2ab4b60ed4923f71926abcedc2ccac8007d09a616982ee431d17a AS tool
RUN \
    set -ux \
 && pip install --no-cache-dir youtube_dl

FROM tool AS product
WORKDIR /app
ARG ARGs
RUN \
    --mount=type=cache,target=/root/.cache/youtube-dl \
    set -ux \
 && youtube-dl --force-ipv4 --output '%(title)s-%(id)s.%(ext)s' $ARGs

FROM scratch
COPY --from=product /app/* /

# DOCKER_BUILDKIT=1 docker build -o=. --build-arg ARGs='--format mp4 -- https://www.youtube.com/watch?v=BXmOlCy0oBM https://www.youtube.com/watch?v=dQw4w9WgXcQ' - <Dockerfile && ls -1 .
# ...
# Dockerfile
# 'Erlang - The Movie (Fixed Audio)-BXmOlCy0oBM.mp4'
# 'Rick Astley - Never Gonna Give You Up (Official Music Video)-dQw4w9WgXcQ.mp4'
