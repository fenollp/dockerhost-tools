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
    - uses: actions/checkout@v2
    - run: ./generate_ci.sh
    - run: git status -sb && [[ 1 -eq \$(git status -sb --name-only | wc -l) ]]
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
	prev=''; grep '^ARG ' "$f" | cut -d: -f2 | cut -c5- \
	| sort -ur \
	| while read -r var; do case "$prev" in "$var"=*) ;; *) echo "$var";; esac; prev=$var; done
}

verifications() {
	local l="$1"; shift
	local f="$1"; shift

	cat_from "$l" "$f" | grep -qE '^## Usage:' || (echo "$f: Missing Usage entry" && exit 1)

	# TODO: ensure --build-arg usage only mentions valid & non-default Dockerfile_ARGs
# Usages... git grep -oE '[-][-]build-arg [^ =]+[ =]' | sed 's%--build-arg%%g;s% %%g;s%=%%g'

	for AS in $(cat_from "$l" "$f" | grep -oE '^## AS [^ :]+:' | sed 's%## AS %%g;s%:%%g'); do
		grep -qE "^FROM scratch AS $AS$" "$f" || (echo "$f: Missing target $AS" && exit 1)
		# TODO: ensure all scratch/out targets are described
	done

	Dockerfile_ARGs "$f" \
	| while read -r ARG; do
		cat_from "$l" "$f" | grep -qE '^## ARG '"$ARG"': ' || (echo "$f: Missing ARG description for $ARG" && exit 1)
	done
}

Usages() {
	local l="$1"; shift
	local f="$1"; shift
	local out="$1"; shift
	for n in $(cat_from "$l" "$f" | grep -nE '^## Usage:' | cut -d: -f1); do
		lusage=$(( l + n ))
		usage=$(cat_from "$(( lusage - 1))" "$f" | head -n1 | sed 's%## %%g')
		cmd=$(cat_from "$lusage" "$f" | head -n1 | cut -c3-)
		next=$(cat_from "$lusage" "$f" | grep -nE '^## Usage:' | cut -d: -f1 | head -n1 || true)
		expecting=$(cat_from "$(( lusage + 1 ))" "$f" | grep -vF '# ```' | cut -c3- | base64 | tr -d '\n')
		if [[ $next -gt 0 ]]; then
			expecting=$(cat_from "$(( lusage + 1 ))" "$f" | grep -vF '# ```' | head -n "$(( next - 1 - 1 ))" | cut -c3- | base64 | tr -d '\n')
		fi
cat <<EOF >>"$out"
    - name: $usage
      run: |
        got=\$(mktemp); expected=\$(mktemp)
        $cmd 1>\$got
        base64 -d <<<'$expecting' >\$expected
        diff --width=150 -y \$expected \$got
    - run: git status -sb && [[ 1 -eq \$(git status -sb --name-only | wc -l) ]]

EOF
	done
}

for d in */; do
	d=${d::-1}
	[[ $d = torrentdl ]] && continue # FIXME
	echo "$d"

	f="$d"/Dockerfile
	l=$(find_start_of_last_matching '^#' "$f")
	verifications "$l" "$f"

cat <<EOF >>"$out"

  ${d}:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ${d}
    steps:
    - uses: docker/login-action@v1
      with:
        username: \${{ secrets.DOCKERHUB_USERNAME }}
        password: \${{ secrets.DOCKERHUB_TOKEN }}
    - uses: actions/checkout@v2
EOF
	Usages "$l" "$f" "$out"
done
