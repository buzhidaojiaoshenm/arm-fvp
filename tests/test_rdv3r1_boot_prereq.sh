#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
launcher="$root/stack/model-scripts/rdinfra/platforms/common_run_model.sh"
wrapper="$root/scripts/run-rdv3r1.sh"

test -x "$root/scripts/apply-rdinfra-fixes.sh"
grep -Fq 'bash "$root/scripts/apply-rdinfra-fixes.sh"' "$root/scripts/sync-rdinfra-stack.sh"
grep -Fq 'source $PWD/../../../sgi/sgi_common_util.sh' "$launcher"
grep -Fq 'MODEL="$model" ./boot-buildroot.sh -p rdv3r1 -j -t' "$wrapper"
