# syntax=docker.io/docker/dockerfile:1@sha256:865e5dd094beca432e8c0a1d5e1c465db5f998dca4e439981029b3b81fb39ed5

FROM --platform=$BUILDPLATFORM docker.io/library/alpine@sha256:4b7ce07002c69e8f3d704a9c5d6fd3053be500b7f1c69fc0d80990c2ad8dd412 AS alpine

FROM alpine AS atomicparsley
WORKDIR /app
RUN \
    set -ux \
# https://github.com/wez/atomicparsley/releases/latest
 && wget https://github.com/wez/atomicparsley/releases/download/20240608.083822.1ed9031/AtomicParsleyAlpine.zip \
 && unzip AtomicParsleyAlpine.zip

# FROM alpine AS mutagen
# RUN \
#     set -ux \
#  && apk add curl
# WORKDIR /app
# RUN \
#     set -ux \
#  && exe=mutagen \
#  && url=https://github.com/mutagen-io/$exe/releases \
#  && lat=$(basename $(curl -#fSLo /dev/null -w '%{url_effective}' $url/latest)) \
#  && bin=${exe}_linux_amd64_$lat \
#  && curl -#fSLo $bin.sha256 $url/download/$lat/SHA256SUMS \
#  && curl -#fSLo $bin.tar.gz $url/download/$lat/$bin.tar.gz \
#  && grep $bin.tar.gz $bin.sha256 | sha256sum -c - \
#  && tar -xf $bin.tar.gz

FROM alpine AS tool
RUN \
  --mount=type=cache,target=/var/cache/apk ln -vs /var/cache/apk /etc/apk/cache && \
    set -ux \
 && apk add \
            ffmpeg \
            gcc \
            git \
            libstdc++ \
            mpv \
            musl-dev \
            py3-pip \
            python3 \
            python3-dev \
# https://github.com/yt-dlp/yt-dlp/tree/4a9bc8c3630378bc29f0266126b503f6190c0430#dependencies
 && pip3 install --no-cache-dir --break-system-packages \
            brotli \
            certifi \
            requests \
            phantomjs \
            pycryptodomex \
            websockets \
            xattr \
#&& pip3 install --no-cache-dir --break-system-packages yt-dlp
#&& pip3 install --no-cache-dir --break-system-packages git+https://github.com/yt-dlp/yt-dlp.git@refs/pull/10354/merge
 && pip3 install --no-cache-dir --break-system-packages git+https://github.com/yt-dlp/yt-dlp.git@master
COPY --from=atomicparsley /app/AtomicParsley /usr/local/bin/
# COPY --from=mutagen /app/mutagen /usr/local/bin/
RUN \
    set -ux \
 && echo --force-ipv4 >>/etc/yt-dlp.conf \
 && echo --downloader ffmpeg >>/etc/yt-dlp.conf \
# NOTE: https://github.com/yt-dlp/yt-dlp/issues/1136#issuecomment-932077195
 && echo "--output '%(title).200s-%(id)s.%(ext)s'" >>/etc/yt-dlp.conf \
 # && echo "--output '%(title).200s-%(id)s-%(extractor_key)s.%(ext)s'" >>/etc/yt-dlp.conf \
 && echo --audio-multistreams >>/etc/yt-dlp.conf \
 && echo --video-multistreams >>/etc/yt-dlp.conf \
 && echo --check-formats >>/etc/yt-dlp.conf \
# https://github.com/yt-dlp/yt-dlp/issues/2875#issuecomment-1055015391
 && echo --abort-on-error >>/etc/yt-dlp.conf \
# TODO: https://github.com/yt-dlp/yt-dlp/issues/2875
 && echo "--sponsorblock-remove 'sponsor,interaction'" >>/etc/yt-dlp.conf \
 && echo --force-keyframes-at-cuts >>/etc/yt-dlp.conf \
 && echo --embed-chapters >>/etc/yt-dlp.conf \
 && echo --embed-info-json >>/etc/yt-dlp.conf \
 && echo --embed-metadata >>/etc/yt-dlp.conf \
# https://github.com/yt-dlp/yt-dlp/issues/2644
# Postprocessing: Unable to embed using ffprobe & ffmpeg;   Stream #1
# Requires AtomicParsley or mutagen
#&& echo --embed-thumbnail >>/etc/yt-dlp.conf
 && echo --embed-subs >>/etc/yt-dlp.conf

# docker buildx build --target=versions --progress=plain  - <./yt-dlp/Dockerfile
# docker buildx build --output=type=local,dest=. --build-arg ARGs='--format mp4/bestvideo*+bestaudio/best -- https://www.youtube.com/watch?v=dQw4w9WgXcQ' --progress=plain --no-cache - <./yt-dlp/Dockerfile
FROM tool AS versions
RUN \
    set -ux \
 && ffmpeg -version \
 && yt-dlp -vU --version \
 && exit 42 # Force showing logs

FROM tool AS product
WORKDIR /app
ARG ARGs
ARG SEPARATOR=' '
RUN \
    --mount=type=cache,target=/root/.cache/yt-dlp \
    set -ux \
#&& cmd="yt-dlp -vU --cache-dir /root/.cache/yt-dlp --newline" \
 && cmd="yt-dlp     --cache-dir /root/.cache/yt-dlp --newline" \
 && case "$ARGs" in *' -f '*) ;; *' --format '*) ;; *' --format='*) ;; *) ARGs="--format 'bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]/bv*+ba/b' $ARGs" ;; esac \
 && cmd="$cmd '$(echo "$ARGs" | sed "s%$SEPARATOR%' '%g")'" \
 && eval $cmd
## ARG DO_NOT_REENCODE: set this to skip re-encoding video (with ffmpeg)
# ARG DO_NOT_REENCODE
# RUN \
#     set -ux \
#  && if [ "${DO_NOT_REENCODE:-}" != '1' ]; then \
#       while read -r vid; do \
#       # if matches 11-char vid id then skip anyway, or maybe under env FEELING_LUCKY=1
# # https://superuser.com/questions/908280/what-is-the-correct-way-to-fix-keyframes-in-ffmpeg-for-dash
#         ffmpeg -i "$vid" -force_key_frames 'expr:gte(t,n_forced*3)' _"$vid" && mv _"$vid" "$vid"; \
# # 11 ? to hopefully only match YouTube IDs
#       done < <(ls -1 *-???????????.* | grep -vE .json$); \
#     fi

FROM scratch
COPY --from=product /app/* /

## ARG SEPARATOR=' ': non-sed-special string that separates given $ARGs
## ARG ARGs: $SEPARATOR-separated CLI arguments
## Usage:
# DOCKER_BUILDKIT=1 docker build --output=type=local,dest=. --build-arg ARGs='--format mp4/bestvideo*+bestaudio/best -- https://www.youtube.com/watch?v=BXmOlCy0oBM https://www.youtube.com/watch?v=dQw4w9WgXcQ' - <Dockerfile && ( ls -1 . && rm 'Erlang： The Movie (Fixed Audio)-BXmOlCy0oBM.mp4' 'Rick Astley - Never Gonna Give You Up (Official Music Video)-dQw4w9WgXcQ.mp4' )
# Dockerfile
# Erlang： The Movie (Fixed Audio)-BXmOlCy0oBM.mp4
# Rick Astley - Never Gonna Give You Up (Official Music Video)-dQw4w9WgXcQ.mp4
