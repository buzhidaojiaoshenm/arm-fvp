#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
temporary_directory=$(mktemp -d)
trap 'rm -rf "$temporary_directory"' EXIT

install_fvp() {
    local archive=$1
    local installer=$2
    local destination=$3

    tar -xzf "$repo_root/$archive" -C "$temporary_directory" "$installer"
    "$temporary_directory/$installer" \
        --no-interactive \
        --i-agree-to-the-contained-eula \
        --force \
        --destination "$destination"
}

install_fvp \
    FVP_RD_V3_R1_11.29_35_Linux64.tgz \
    FVP_RD_V3_R1.sh \
    "$repo_root/models/rdv3r1"
install_fvp \
    FVP_RD_V3_R1_Cfg1_11.29_35_Linux64.tgz \
    FVP_RD_V3_R1_Cfg1.sh \
    "$repo_root/models/rdv3r1-cfg1"
