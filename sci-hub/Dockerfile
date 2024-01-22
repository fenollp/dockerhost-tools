# syntax=docker.io/docker/dockerfile:1@sha256:ac85f380a63b13dfcefa89046420e1781752bab202122f8f50032edf31be0021

ARG ARGs=
ARG SEPARATOR=' '

FROM --platform=$BUILDPLATFORM docker.io/library/alpine@sha256:51b67269f354137895d43f3b3d810bfacd3945438e94dc5ac55fdac340352f48 AS tool
RUN set -eux \
 && apk update \
 && apk add \
            bash \
            bind-tools \
            curl
SHELL ["/bin/bash", "-c", "-eux"]

FROM tool AS product
WORKDIR /app
ARG ARGs
ARG SEPARATOR=' '
RUN <<EOF
cmd=()

# See https://sci-hub.ru/mirrors => .se .st .ru
declare -a sites=(sci-hub.ru sci-hub.se sci-hub.st)
picked=$(($RANDOM % ${#sites[@]}))
site=${sites[$picked]}
unset picked

# NOTE: for some reason, +trace goes around censors
ip=$(dig "$site" +trace @1.1.1.1 | grep -F "$site". | grep -F "$(printf 'IN\tA\t')" | tail -n1 | cut -f6)
[[ "$ip" = '' ]] && echo "Could not resolve $site" && exit 2
echo "Resolved $site to $ip"

cmd+=(--resolve "$site":443:"$ip")
cmd+=(--header "Host: $site")

rv=$RANDOM
useragent="Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:$rv.0) Gecko/20100101 Firefox/$rv.0"
cmd+=(-A "$useragent")

[[ "$ARGs" = '' ]] && echo 'Needs at least one link to a paper' && exit 2
for arg in $ARGs; do
  [[ $arg != *" "* ]]

  curl -#fsSLo _ "${cmd[@]}" https://"$site"/"$arg"

  ddl=$(grep -F 'location.href=' _ | cut -d"'" -f2)
  if [[ "$ddl" = '' ]]; then
    if grep -F '<title>Sci-Hub:' _ >/dev/null 2>&1; then
      echo "Can't find $arg" && exit 2
    fi
    cat _ && exit 2
  fi
  rm _

  filename=$(sed 's%.*/%%;s%?.*%%' <<<"$ddl")

  curl -#fsSLo "$filename" "${cmd[@]}" https://"$site"/"$ddl"
done
EOF

FROM scratch
COPY --link=true --from=product /app/* /

## ARG SEPARATOR=' ': non-sed-special string that separates given $ARGs
## ARG ARGs=: space-separated URLs (prefer DOIs)
## Usage: some papers
# DOCKER_BUILDKIT=1 docker build -o=. --build-arg ARGs='https://doi.org/10.1016/j.solener.2020.07.011 https://doi.org/10.3390/jsan9030035' - <Dockerfile && ( ls -1t ./*.pdf; rm ./*.pdf )
# ./nawaz2020.pdf
# ./10.1016@j.solener.2020.07.011.pdf
