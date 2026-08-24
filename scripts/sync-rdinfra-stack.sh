#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
repo_bin="$repo_root/.tools/bin/repo"

mkdir -p "$(dirname "$repo_bin")" "$repo_root/stack"

if [[ ! -x $repo_bin ]]; then
    curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo -o "$repo_bin"
    chmod 0755 "$repo_bin"
fi

cd "$repo_root/stack"

local_manifest_dir="$PWD/.repo/local_manifests"
local_manifest_override=
if [[ -d "$local_manifest_dir" ]]; then
    local_manifest_override=$(find "$local_manifest_dir" -mindepth 1 -maxdepth 1 \( -type f -o -type l \) -name '*.xml' -print -quit)
fi
if [[ -n "$local_manifest_override" ]]; then
    printf 'Refusing to sync: local manifest override(s) found in %s.\n' "$local_manifest_dir" >&2
    printf 'Remove or rename the *.xml override files, then rerun this script.\n' >&2
    exit 1
fi

"$repo_bin" init \
    -u https://git.gitlab.arm.com/infra-solutions/reference-design/infra-refdesign-manifests.git \
    -m pinned-rdv3r1.xml \
    -b refs/tags/RD-INFRA-2025.07.03 \
    --depth=1

"$repo_bin" sync -c -j "$(nproc)" --fetch-submodules --force-sync --no-clone-bundle
