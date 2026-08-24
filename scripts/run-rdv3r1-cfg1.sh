#!/usr/bin/env bash

set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
model=$(find "$root/models/rdv3r1-cfg1/models" -type f -name FVP_RD_V3_R1_Cfg1 -executable -print -quit)
test -n "$model"

cd "$root/stack/model-scripts/rdinfra"
MODEL="$model" ./boot-buildroot.sh -p rdv3r1cfg1 -j -t
