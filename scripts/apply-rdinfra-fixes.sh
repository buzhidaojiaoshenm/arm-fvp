#!/usr/bin/env bash

set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

apply_once() {
    local repository=$1
    local patch=$2

    if git -C "$repository" apply --unidiff-zero --reverse --check "$patch" >/dev/null 2>&1; then
        return
    fi

    git -C "$repository" apply --unidiff-zero --check "$patch"
    git -C "$repository" apply --unidiff-zero "$patch"
}

apply_once "$root/stack/container-scripts" \
    "$root/patches/rdinfra-2025.07.03/container-proxy.patch"
apply_once "$root/stack/model-scripts" \
    "$root/patches/rdinfra-2025.07.03/model-script-helper-path.patch"
