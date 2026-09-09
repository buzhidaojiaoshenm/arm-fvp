#!/usr/bin/env bash

set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
model=$(find "$root/models/rdv3r1/models" -type f -name FVP_RD_V3_R1 -executable -print -quit)
test -n "$model"

case ${1:-} in
    '') interactive=false ;;
    --interactive) interactive=true ;;
    *)
        printf 'Usage: %s [--interactive]\n' "${0##*/}" >&2
        exit 2
        ;;
esac

cd "$root/stack/model-scripts/rdinfra"
if [[ $interactive == true ]]; then
    MODEL="$model" ./boot-buildroot.sh -p rdv3r1
else
    MODEL="$model" ./boot-buildroot.sh -p rdv3r1 -j -t
fi
