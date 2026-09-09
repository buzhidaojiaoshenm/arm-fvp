#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

git submodule sync --recursive
git submodule init

if ! git submodule update --init --recursive --depth=1 --jobs "$(nproc)"; then
    printf 'Shallow submodule update failed; retrying without --depth.\n' >&2
    git submodule update --init --recursive --jobs "$(nproc)"
fi

edk2="$repo_root/stack/uefi/edk2"
platforms="$repo_root/stack/uefi/edk2-platforms"
nested_platforms="$edk2/edk2-platforms"

test -d "$platforms"
platforms_head=$(git -C "$platforms" rev-parse HEAD)

if [[ ! -e "$nested_platforms" && ! -L "$nested_platforms" ]]; then
    ln -s ../edk2-platforms "$nested_platforms"
elif [[ -L "$nested_platforms" ]]; then
    if [[ $(readlink "$nested_platforms") != ../edk2-platforms ]]; then
        printf 'Refusing to replace unexpected EDK2 Platforms symlink: %s\n' \
            "$nested_platforms" >&2
        exit 1
    fi
elif git -C "$nested_platforms" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    nested_head=$(git -C "$nested_platforms" rev-parse HEAD)
    if [[ $nested_head != "$platforms_head" ]]; then
        printf 'Existing nested EDK2 Platforms checkout is at %s, expected %s.\n' \
            "$nested_head" "$platforms_head" >&2
        exit 1
    fi
else
    printf 'Refusing to replace existing non-Git path: %s\n' "$nested_platforms" >&2
    exit 1
fi

exclude_file=$(git -C "$edk2" rev-parse --git-path info/exclude)
grep -Fxq '/edk2-platforms' "$exclude_file" || printf '/edk2-platforms\n' >> "$exclude_file"

bash "$repo_root/scripts/apply-rdinfra-fixes.sh"
