#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

require_model() {
    local name=$1
    local directory=$2
    local model

    if [[ ! -d $directory ]]; then
        printf 'missing model directory %s\n' "$directory" >&2
        return 1
    fi

    model=$(find "$directory" -type f -name "$name" -perm -111 -print -quit)
    if [[ -z $model ]]; then
        printf 'missing executable %s under %s\n' "$name" "$directory" >&2
        return 1
    fi

    printf '%s\n' "$model"
}

require_model FVP_RD_V3_R1 "$repo_root/models/rdv3r1/models"
require_model FVP_RD_V3_R1_Cfg1 "$repo_root/models/rdv3r1-cfg1/models"
