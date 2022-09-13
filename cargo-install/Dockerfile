# syntax=docker.io/docker/dockerfile:1@sha256:9ba7531bd80fb0a858632727cf7a112fbfd19b17e94c4e84ced81e24ef1a0dbc

ARG ARGs=
ARG SEPARATOR=' '

FROM --platform=$BUILDPLATFORM docker.io/library/rust:1@sha256:c83026a50422024a35b8daf0ac9182b5d75c684e7d5fa7a1064f9fddf7b89f42 AS tool
ENV CARGO_HOME /root/.cargo_home
ARG ARGs
ARG SEPARATOR
RUN \
  # TODO: setup cache for rustup-installed & apt-installed things
    set -ux \
 && target= \
 && now= \
 && for part in $(echo "$ARGs" | sed "s%--target=%--target$SEPARATOR%"); do \
        if [ "$now" = 't' ]; then target="$part"; break; fi; \
        if [ "$part" = '--target' ]; then now=t; fi \
    done \
 && if [ -n "$target" ]; then rustup target add "$target"; fi

FROM tool AS product
WORKDIR /app
ARG CRATE
ARG VERSION
ARG ARGs
ARG SEPARATOR
RUN \
  # --mount=type=cache,target=/root/.cargo_home/bin/ \ Replaced with --root=/app
  --mount=type=cache,target=/root/.cargo_home/git/db/ \
  --mount=type=cache,target=/root/.cargo_home/registry/cache/ \
  --mount=type=cache,target=/root/.cargo_home/registry/index/ \
    set -ux \
 && [ -n "$CRATE" ] \
 && [ -n "$VERSION" ] \
 && cmd="cargo install --locked --root=/app $CRATE@$VERSION" \
 && if [ -n "$ARGs" ]; then cmd="$cmd '$(echo "$ARGs" | sed "s%$SEPARATOR%' '%g")'"; fi \
 && eval $cmd

FROM scratch
COPY --from=product /app/bin/* /

## ARG CRATE: name of the binary crate found at https://crates.io/
## ARG VERSION: exact version of the $CRATE
## ARG SEPARATOR=' ': non-sed-special string that separates given $ARGs
## ARG ARGs=: $SEPARATOR-separated CLI arguments
## Usage: some binary crate
# DOCKER_BUILDKIT=1 docker build -o=. --build-arg CRATE=tokei --build-arg VERSION=12.1.2 - <Dockerfile && ( ./tokei && rm 'tokei' )
# ===============================================================================
#  Language            Files        Lines         Code     Comments       Blanks
# ===============================================================================
#  Dockerfile              1           60           33           22            5
# ===============================================================================
#  Total                   1           60           33           22            5
# ===============================================================================
## Usage: an example with a MUSL target
# DOCKER_BUILDKIT=1 docker build -o=. --build-arg CRATE=termtree --build-arg VERSION=0.4.0 --build-arg ARGs='--example tree --target x86_64-unknown-linux-musl' - <Dockerfile && ( ./tree | wc -l && rm 'tree' )
# 4
## Usage: dynamically linked and setting some features
# DOCKER_BUILDKIT=1 docker build -o=. --build-arg CRATE=diesel_cli --build-arg VERSION=2.0.0 --build-arg ARGs='--no-default-features --features postgres' - <Dockerfile && ( ./diesel --version && rm 'diesel' )
# diesel 2.0.0
