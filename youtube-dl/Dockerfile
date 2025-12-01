# syntax=docker.io/docker/dockerfile:1@sha256:42399d4635eddd7a9b8a24be879d2f9a930d0ed040a61324cfdf59ef1357b3b2


FROM --platform=$BUILDPLATFORM docker.io/library/python:alpine@sha256:8373231e1e906ddfb457748bfc032c4c06ada8c759b7b62d9c73ec2a3c56e710 AS python


FROM python AS tool
ARG PIP_PACKAGE=youtube_dl
RUN \
    set -ux \
 && apk add --no-cache git \
 && pip install --no-cache-dir $PIP_PACKAGE

FROM tool AS product
WORKDIR /app
ARG ARGs
ARG SEPARATOR=' '
RUN \
    --mount=type=cache,target=/root/.cache/youtube-dl \
    set -ux \
 && cmd="youtube-dl --cache-dir /root/.cache/youtube-dl --newline --force-ipv4 --output '%(title)s-%(id)s.%(ext)s'" \
 && cmd="$cmd '$(echo "$ARGs" | sed "s%$SEPARATOR%' '%g")'" \
 && eval $cmd

FROM scratch
COPY --from=product /app/* /

## ARG SEPARATOR=' ': non-sed-special string that separates given $ARGs
## ARG ARGs: $SEPARATOR-separated CLI arguments
## ARG PIP_PACKAGE=youtube_dl: the package name or archive path to pip-install
## Usage:
# DOCKER_BUILDKIT=1 docker build -o=. --build-arg ARGs='--format mp4 -- https://www.youtube.com/watch?v=BXmOlCy0oBM https://www.youtube.com/watch?v=dQw4w9WgXcQ' - <Dockerfile && ( ls -1 . && rm 'Erlang - The Movie (Fixed Audio)-BXmOlCy0oBM.mp4' 'Rick Astley - Never Gonna Give You Up (Official Music Video)-dQw4w9WgXcQ.mp4' )
# Dockerfile
# Erlang - The Movie (Fixed Audio)-BXmOlCy0oBM.mp4
# Rick Astley - Never Gonna Give You Up (Official Music Video)-dQw4w9WgXcQ.mp4
