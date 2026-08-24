#!/usr/bin/env bash

set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

cd "$root/stack/container-scripts"
./container.sh build
tty_args=()
if [[ -t 0 && -t 1 ]]; then
    tty_args=(-t -i)
fi
runtime_proxy_args=()
[[ -v HTTP_PROXY ]] && runtime_proxy_args+=(--env "HTTP_PROXY=${HTTP_PROXY}")
[[ -v HTTPS_PROXY ]] && runtime_proxy_args+=(--env "HTTPS_PROXY=${HTTPS_PROXY}")
[[ -v ALL_PROXY ]] && runtime_proxy_args+=(--env "ALL_PROXY=${ALL_PROXY}")
[[ -v http_proxy ]] && runtime_proxy_args+=(--env "http_proxy=${http_proxy}")
[[ -v https_proxy ]] && runtime_proxy_args+=(--env "https_proxy=${https_proxy}")
[[ -v all_proxy ]] && runtime_proxy_args+=(--env "all_proxy=${all_proxy}")
docker run --rm \
    --network host \
    -v "$root/stack:$root/stack" -w "$root/stack" \
    --mount type=volume,dst="$HOME" \
    --env ARCADE_USER="$(id -un)" --env ARCADE_UID="$(id -u)" --env ARCADE_GID="$(id -g)" \
    "${runtime_proxy_args[@]}" \
    "${tty_args[@]}" rdinfra-builder \
    bash -c 'git config --global url."https://git.savannah.gnu.org/git/gnulib.git".insteadOf git://git.sv.gnu.org/gnulib && \
             ./build-scripts/rdinfra/build-test-buildroot.sh -p rdv3r1cfg1 build && \
             ./build-scripts/rdinfra/build-test-buildroot.sh -p rdv3r1cfg1 package'
