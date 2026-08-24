#!/usr/bin/env bash

set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

for file in install-fvps sync-rdinfra-stack build-rdv3r1 run-rdv3r1 build-rdv3r1-cfg1 run-rdv3r1-cfg1; do
    test -x "$root/scripts/$file.sh"
done

grep -Fq 'RD-INFRA-2025.07.03' "$root/docs/rdv3r1-fvp-runbook.md"
grep -Fq 'Buildroot' "$root/docs/rdv3r1-fvp-runbook.md"
