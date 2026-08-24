#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
repo_bin="$repo_root/.tools/bin/repo"
manifest="$repo_root/stack/.repo/manifest.xml"
manifest_repo="$repo_root/stack/.repo/manifests.git"
local_manifest_dir="$repo_root/stack/.repo/local_manifests"
resolved_manifest=$(mktemp)
expected_resolved_manifest_sha256=e1c7acacce62be3d90689677669f014188bb2fcad579bfe3d9ed97b4009770c3
trap 'rm -f "$resolved_manifest"' EXIT

test -x "$repo_bin"
if [[ -d "$local_manifest_dir" ]]; then
    local_manifest_override=$(find "$local_manifest_dir" -mindepth 1 -maxdepth 1 \( -type f -o -type l \) -name '*.xml' -print -quit)
    test -z "$local_manifest_override"
fi
test -f "$manifest"
grep -Fxq '  <include name="pinned-rdv3r1.xml" />' "$manifest"
git -C "$manifest_repo" describe --exact-match --tags HEAD | grep -Fxq 'RD-INFRA-2025.07.03'
(
    cd "$repo_root/stack"
    "$repo_bin" manifest -r
) > "$resolved_manifest"
grep -Fxq '<manifest>' "$resolved_manifest"
actual_resolved_manifest_sha256=$(sha256sum "$resolved_manifest" | awk '{print $1}')
test "$actual_resolved_manifest_sha256" = "$expected_resolved_manifest_sha256"
test -d "$repo_root/stack/build-scripts"
test -d "$repo_root/stack/model-scripts"
