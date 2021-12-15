# syntax=docker.io/docker/dockerfile:1@sha256:42399d4635eddd7a9b8a24be879d2f9a930d0ed040a61324cfdf59ef1357b3b2


FROM --platform=$BUILDPLATFORM docker.io/library/alpine@sha256:21a3deaa0d32a8057914f36584b5288d2e5ecc984380bc0118285c70fa8c9300 AS alpine
FROM --platform=$BUILDPLATFORM docker.io/stablebaselines/rl-baselines3-zoo-cpu:1.3.0@sha256:334dc0127059587c269c091b04664878707720ff93c766a9d19a3f84385a5ade AS rl-baselines3-zoo-cpu


FROM alpine AS bs3-zoo-src
WORKDIR /w
ARG SB3_ZOO_COMMIT=master
RUN \
    set -ux \
 && apk add --no-cache git \
 && git init \
 && git remote add origin https://github.com/DLR-RM/rl-baselines3-zoo \
 && git fetch --depth 1 origin $SB3_ZOO_COMMIT \
 && git checkout FETCH_HEAD \
 && rm -rf logs \
 && rm -rf .git


FROM scratch AS mujoco-tarball
ARG MUJOCO_VERSION=mujoco210-linux-x86_64
ADD https://mujoco.org/download/$MUJOCO_VERSION.tar.gz /tarball.tar.gz

FROM alpine AS mujoco
WORKDIR /w
RUN \
    --mount=from=mujoco-tarball,source=/tarball.tar.gz,target=/tarball.tar.gz \
    set -ux \
 && tar xf /tarball.tar.gz


FROM rl-baselines3-zoo-cpu AS tool
COPY --from=bs3-zoo-src /w /root/code/rl_zoo
WORKDIR /root/code/rl_zoo
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
 && apt install -y patchelf libosmesa6-dev
RUN \
    --mount=from=mujoco,source=/w,target=/root/.mujoco \
    set -ux \
 && pip3 install 'mujoco-py<2.2,>=2.1' \
 && export LD_LIBRARY_PATH=$(echo /root/.mujoco/*/bin) \
 && python3 -c "import mujoco_py; assert mujoco_py.__version__.startswith('2.1')"


FROM tool AS product
ARG ALGO_NAME=td3
ARG ENV_ID=Hopper-v3
ARG ARGs=
ARG SEPARATOR=' '
RUN \
    --mount=from=mujoco,source=/w,target=/root/.mujoco \
    set -ux \
 && cmd="python train.py --algo $ALGO_NAME --env $ENV_ID --tensorboard-log logs/tensorboard/" \
 && if [ -n "$ARGs" ]; then cmd="$cmd '$(echo "$ARGs" | sed "s%$SEPARATOR%' '%g")'"; fi \
 && export LD_LIBRARY_PATH=$(echo /root/.mujoco/*/bin) \
 && eval $cmd


FROM scratch
COPY --from=product /root/code/rl_zoo/logs/* /


## ARG SEPARATOR=' ': non-sed-special string that separates given $ARGs
## ARG ARGs=: $SEPARATOR-separated CLI arguments
## ARG ALGO_NAME=td3: Algorithm name given to train.py --algo
## ARG ENV_ID=Hopper-v3: Environment ID given to train.py --env
## ARG SB3_ZOO_COMMIT=master: Commit hash for requested https://github.com/DLR-RM/rl-baselines3-zoo/commits
## ARG MUJOCO_VERSION=mujoco210-linux-x86_64: Version of MuJoCo to use, from https://mujoco.org/download
## Usage:
# DOCKER_BUILDKIT=1 docker build -o=. --build-arg ARGs='-n 100' --progress=plain - <Dockerfile && ls -1 . #&& tensorboard --logdir .
# Dockerfile
# Hopper-v3
# Hopper-v3_1
