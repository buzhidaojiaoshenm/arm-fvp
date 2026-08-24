#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
script="$root/stack/container-scripts/container.sh"

test -x "$root/scripts/apply-rdinfra-fixes.sh"
grep -Fq 'bash "$root/scripts/apply-rdinfra-fixes.sh"' "$root/scripts/sync-rdinfra-stack.sh"
grep -Fq -- '--build-arg "HTTP_PROXY=${HTTP_PROXY}"' "$script"
grep -Fq -- '--build-arg "HTTPS_PROXY=${HTTPS_PROXY}"' "$script"
grep -Fq -- '--build-arg "ALL_PROXY=${ALL_PROXY}"' "$script"
grep -Fq -- 'curl --fail --location --retry 3' "$root/stack/container-scripts/common/install-clang.sh"
grep -Fq -- '[[ -t 0 && -t 1 ]]' "$root/scripts/build-rdv3r1.sh"
grep -Fq -- 'runtime_proxy_args+=(--env "HTTP_PROXY=${HTTP_PROXY}")' "$root/scripts/build-rdv3r1.sh"
grep -Fq -- 'runtime_proxy_args+=(--env "HTTPS_PROXY=${HTTPS_PROXY}")' "$root/scripts/build-rdv3r1.sh"
grep -Fq -- 'runtime_proxy_args+=(--env "ALL_PROXY=${ALL_PROXY}")' "$root/scripts/build-rdv3r1.sh"
grep -Fq -- '--network host' "$root/scripts/build-rdv3r1.sh"
grep -Fq -- 'url."https://git.savannah.gnu.org/git/gnulib.git".insteadOf git://git.sv.gnu.org/gnulib' "$root/scripts/build-rdv3r1.sh"
