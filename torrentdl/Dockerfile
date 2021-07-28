# syntax=docker/dockerfile:1.2

FROM --platform=$BUILDPLATFORM alpine AS tool
RUN \
  --mount=type=cache,target=/var/cache/apk ln -vs /var/cache/apk /etc/apk/cache && \
    set -ux \
 && apk add aria2

FROM tool AS product
WORKDIR /app
ARG MAGNET
RUN \
    set -ux \
 && aria2c --log=- --dir=. "$MAGNET" \
 && ls -lha .

FROM scratch
COPY --from=product /app/* /

# Unfortunately a torrent client needs to open (UDP) ports which is not supported!

# cat Dockerfile | DOCKER_BUILDKIT=1 DOCKER_HOST=ssh://... docker build --build-arg MAGNET='...' -o=. --progress=plain --network=host -
