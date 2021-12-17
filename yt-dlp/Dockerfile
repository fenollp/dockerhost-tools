# syntax=docker/dockerfile:1@sha256:42399d4635eddd7a9b8a24be879d2f9a930d0ed040a61324cfdf59ef1357b3b2

FROM --platform=$BUILDPLATFORM docker.io/library/python:alpine@sha256:78604a29496b7a1bd5ea5c985d69a0928db7ea32fcfbf71bbde3e317fdd9ac5e AS tool
RUN \
  --mount=type=cache,target=/var/cache/apk ln -vs /var/cache/apk /etc/apk/cache && \
    set -ux \
 && apk add --no-cache --virtual .build-deps gcc musl-dev \
 && pip install --no-cache-dir pycrypto yt-dlp \
 && apk del .build-deps \
 && apk add --no-cache ffmpeg \
 && echo --force-ipv4 >>/etc/yt-dlp.conf \
 && echo "--output '%(title)s-%(id)s.%(ext)s'" >>/etc/yt-dlp.conf \
 && echo --audio-multistreams >>/etc/yt-dlp.conf \
 && echo --video-multistreams >>/etc/yt-dlp.conf \
 && echo --abort-on-error >>/etc/yt-dlp.conf \
 && echo --embed-subs >>/etc/yt-dlp.conf \
 && echo --embed-thumbnail >>/etc/yt-dlp.conf \
 && echo --embed-metadata >>/etc/yt-dlp.conf \
 && echo --embed-chapters >>/etc/yt-dlp.conf \
 && echo "--sponsorblock-remove 'sponsor,interaction'" >>/etc/yt-dlp.conf

FROM tool AS product
WORKDIR /app
ARG ARGs
ARG SEPARATOR=' '
RUN \
    --mount=type=cache,target=/root/.cache/yt-dlp \
    set -ux \
 && cmd="yt-dlp --cache-dir /root/.cache/yt-dlp --newline" \
 && cmd="$cmd '$(echo "$ARGs" | sed "s%$SEPARATOR%' '%g")'" \
 && eval $cmd

FROM scratch
COPY --from=product /app/* /

## ARG SEPARATOR=' ': non-sed-special string that separates given $ARGs
## ARG ARGs: $SEPARATOR-separated CLI arguments
## Usage:
# DOCKER_BUILDKIT=1 docker build -o=. --build-arg ARGs='--format mp4 -- https://www.youtube.com/watch?v=BXmOlCy0oBM https://www.youtube.com/watch?v=dQw4w9WgXcQ' - <Dockerfile && ( ls -1 . && rm 'Erlang - The Movie (Fixed Audio)-BXmOlCy0oBM.mp4' 'Rick Astley - Never Gonna Give You Up (Official Music Video)-dQw4w9WgXcQ.mp4' )
# Dockerfile
# Erlang - The Movie (Fixed Audio)-BXmOlCy0oBM.mp4
# Rick Astley - Never Gonna Give You Up (Official Music Video)-dQw4w9WgXcQ.mp4
