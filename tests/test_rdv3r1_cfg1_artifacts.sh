#!/usr/bin/env bash

set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

test -e "$root/stack/output/rdv3r1cfg1/rdv3r1cfg1/fip-uefi.bin"
test -e "$root/stack/output/rdv3r1cfg1/rdv3r1cfg1/Image"
