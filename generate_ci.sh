#!/bin/bash -eu
set -o pipefail

out=.github/workflows/ci.yml

mkdir -p "$(dirname $out)"

cat <<EOF >"$out"
name: Build
on:
  push: {}
jobs:
  metaci:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - run: ./generate_ci.sh
    - run: git status -sb && [[ 1 -eq \$(git status -sb | wc -l) ]]
EOF

find_start_of_last_matching() {
	local pat="$1"; shift
	local f="$1"; shift
	local start=0
	local cont=$start
	while read -r n; do
		if [[ $n -eq $cont ]]; then
			cont=$(( cont + 1 ))
			continue
		fi
		start=$n
		cont=$(( start + 1 ))
	done < <(grep -nE "$pat" "$f" | cut -d: -f1)
	echo "$start"
}

cat_from() {
	local l="$1"; shift
	local f="$1"; shift
	sed -n "$l",9999p "$f"
}

Dockerfile_ARGs() {
	local f="$1"; shift
	local prev=''
	grep '^ARG ' "$f" | cut -c5- \
	| sort -ur \
	| while read -r var; do case "$prev" in "$var"=*) ;; *) echo "$var";; esac; prev=$var; done
}

verifications() {
	local l="$1"; shift
	local f="$1"; shift

	cat_from "$l" "$f" | grep -qE '^## Usage:' || (echo "$f: Missing Usage entry" && exit 1)

	cat_from "$l" "$f" | grep -oE '^## AS [^ :]+:' | sed 's%## AS %%g;s%:%%g' \
	| while read -r AS; do
		grep -qE "^FROM scratch AS $AS$" "$f" || (echo "$f: Missing target $AS" && exit 1)
	done || true
	grep -oE '^FROM scratch AS out-[^-]+$' "$f" | sed 's%FROM scratch AS out-%%g' \
	| while read -r AS; do
		grep -qE "^## AS out-$AS:" "$f" || (echo "$f: Missing target description for $AS" && exit 1)
	done || true

	Dockerfile_ARGs "$f" \
	| while read -r ARG; do
		cat_from "$l" "$f" | grep -qE '^## ARG '"$ARG"': ' || (echo "$f: Missing ARG description for $ARG" && exit 1)
	done
	cat_from "$l" "$f" | grep -oE '[-][-]build-arg [^ =]+[ =]' | sed 's%--build-arg%%g;s% %%g;s%=%%g' | sort -u \
	| while read -r ARG; do
		grep -qE "^## ARG $ARG[:=]" "$f" || (echo "$f: Unexpected usage of ARG $ARG" && exit 1)
	done
}

Usages() {
	local l="$1"; shift
	local f="$1"; shift
	local out="$1"; shift
	for n in $(cat_from "$l" "$f" | grep -nE '^## Usage:' | cut -d: -f1); do
		lusage=$(( l + n ))
		usage=$(cat_from "$(( lusage - 1))" "$f" | head -n1 | sed 's%## Usage:%%g')
		cmd=$(cat_from "$lusage" "$f" | head -n1 | cut -c3-)
		next=$(cat_from "$lusage" "$f" | grep -nE '^## Usage:' | cut -d: -f1 | head -n1 || true)
		expecting=$(cat_from "$(( lusage + 1 ))" "$f" | grep -vF '# ```' | cut -c3- | base64 | tr -d '\n')
		if [[ $next -gt 0 ]]; then
			expecting=$(cat_from "$(( lusage + 1 ))" "$f" | grep -vF '# ```' | head -n "$(( next - 1 - 1 ))" | cut -c3- | base64 | tr -d '\n')
		fi
cat <<EOF >>"$out"
    - run: |
        echo GOT=\$(mktemp) >>\$GITHUB_ENV
        EXPECTED=\$(mktemp)
        base64 -d <<<'$expecting' >\$EXPECTED
        echo EXPECTED=\$EXPECTED >>\$GITHUB_ENV
    - run: |
        $cmd 1>\$GOT
EOF
	if [[ -n "$usage" ]]; then
cat <<EOF >>"$out"
      name: "$usage"
EOF
	fi
cat <<EOF >>"$out"
    - run: |
        echo expected:
        cat -A \$EXPECTED
        echo got:
        cat -A \$GOT
        echo diff:
        diff --width=150 -y \$EXPECTED \$GOT
    - run: git status -sb && [[ 1 -eq \$(git status -sb | wc -l) ]]

EOF
	done
}

for d in */; do
	d=${d::-1}
	echo "$d"

	f="$d"/Dockerfile
	l=$(find_start_of_last_matching '^#' "$f")
	verifications "$l" "$f"

cat <<EOF >>"$out"

  ${d}:
    needs: metaci
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ${d}
    steps:
    - uses: actions/checkout@v4
    - uses: docker/login-action@v3
      with:
        username: \${{ secrets.DOCKERHUB_USERNAME }}
        password: \${{ secrets.DOCKERHUB_TOKEN }}
EOF
	Usages "$l" "$f" "$out"
done
