# syntax=docker.io/docker/dockerfile:1@sha256:865e5dd094beca432e8c0a1d5e1c465db5f998dca4e439981029b3b81fb39ed5

FROM --platform=$BUILDPLATFORM docker.io/library/golang:1@sha256:81bf5927dc91aefb42e2bc3a5abdbe9bb3bae8ba8b107e2a4cf43ce3402534c6 AS golang

FROM golang AS tool
RUN \
  --mount=type=cache,target=/go/pkg/mod \
  --mount=type=cache,target=/root/.cache/go-build \
    set -ux \
 && CGO_ENABLED=0 go install github.com/fogleman/primitive@latest

# FROM golang AS product
# WORKDIR /app
# COPY --from=tool /go/bin/primitive /
# ARG IMG_URL
# ADD $IMG_URL /img
# ARG ARGs
# RUN \
#     /primitive -i /img $ARGs
FROM scratch AS product
WORKDIR /app
COPY --from=tool /go/bin/primitive /
ARG IMG_URL
ADD $IMG_URL /img
ARG ARGs
SHELL ["/bin/sh", "-eux", "-c"]
RUN \
  --mount=from=golang,src=/bin/sh,dst=/bin/sh \
  --mount=from=golang,src=/lib/x86_64-linux-gnu/libc.so.6,dst=/lib/x86_64-linux-gnu/libc.so.6 \
  --mount=from=golang,src=/lib64/ld-linux-x86-64.so.2,dst=/lib64/ld-linux-x86-64.so.2 \
    /primitive -i /img $ARGs

FROM scratch
COPY --from=product /app/* /

## ARG ARGs: Arguments defined at https://github.com/fogleman/primitive/blob/0373c216458be1c4b40655b796a3aefedf8b7d23/README.md#command-line-usage
## ARG IMG_URL: HTTP(S) URL of the input image file
## Usage:
# DOCKER_BUILDKIT=1 docker build --output=type=local,dest=. --build-arg IMG_URL='https://img.freepik.com/free-vector/hand-drawn-fresh-pineapple-vector_53876-108732.jpg?t=st=1728727735~exp=1728731335~hmac=8c5e57ed27047cf4e179a33d9c010b2a624a9f9502c181b278c7b4cace21e1d5&w=740' --build-arg ARGs='-o output.svg -rep 9 -m 6 -n 99 -v -bg FFF' - <Dockerfile && ( ls -1 . && rm output.svg )
# Dockerfile
# output.svg
