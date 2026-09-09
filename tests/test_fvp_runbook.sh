#!/usr/bin/env bash

set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

for file in install-fvps sync-rdinfra-stack build-rdv3r1 run-rdv3r1 build-rdv3r1-cfg1 run-rdv3r1-cfg1; do
    test -x "$root/scripts/$file.sh"
done

grep -Fq 'RD-INFRA-2025.07.03' "$root/docs/rdv3r1-fvp-runbook.md"
grep -Fq 'Buildroot' "$root/docs/rdv3r1-fvp-runbook.md"
grep -Fq 'git clone --recurse-submodules --shallow-submodules' "$root/README.md"
grep -Fq 'Git submodule' "$root/docs/rdv3r1-fvp-runbook.md"

separator_count=$(grep -c '^| ---' "$root/README.md" || true)
test "$separator_count" -ge 4

if grep -Eq '^[[:space:]]+[━─]+([[:space:]]+[━─]+)+[[:space:]]*$' "$root/README.md"; then
    printf 'README still contains terminal-style table separators\n' >&2
    exit 1
fi

if grep -Eq 'Google repo|infra-refdesign-manifests' \
    "$root/README.md" "$root/docs/rdv3r1-fvp-runbook.md"; then
    printf 'Documentation still describes the legacy Repo manifest workflow\n' >&2
    exit 1
fi
