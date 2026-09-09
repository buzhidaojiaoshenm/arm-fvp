#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

test -f .gitmodules

submodule_count=$(git config -f .gitmodules --get-regexp '^submodule\..*\.path$' | wc -l)
test "$submodule_count" -eq 19

while IFS=$'\t' read -r name path url sha; do
    test "$(git config -f .gitmodules --get "submodule.$name.path")" = "$path"
    test "$(git config -f .gitmodules --get "submodule.$name.url")" = "$url"
    test "$(git config -f .gitmodules --get "submodule.$name.shallow")" = true
    test "$(git config -f .gitmodules --get "submodule.$name.ignore")" = untracked

    read -r mode index_sha _ < <(git ls-files --stage -- "$path")
    test "$mode" = 160000
    test "$index_sha" = "$sha"
done <<'SUBMODULES'
build-scripts	stack/build-scripts	https://git.gitlab.arm.com/infra-solutions/reference-design/scripts/build-scripts	39a69c81a8bbaf7dd90e472bedf759cb2d1a9ff5
buildroot	stack/buildroot	https://git.gitlab.arm.com/infra-solutions/reference-design/platsw/buildroot	bb43b43528dbdf517dce9a582b897a1b4883e7d4
busybox	stack/busybox	https://github.com/mirror/busybox	1a64f6a20aaf6ea4dbba68bbfa8cc1ab7e5c57c4
container-scripts	stack/container-scripts	https://git.gitlab.arm.com/infra-solutions/reference-design/scripts/container-scripts	7c67d3942bb0c392011e96b74022d03577ac76c9
grub	stack/grub	https://git.savannah.gnu.org/git/grub.git	2a2e10c1b39672de3d5da037a50d5c371f49b40d
hafnium	stack/hafnium	https://git.trustedfirmware.org/hafnium/hafnium.git	bd2fc0e099a19a8af300d36cb3d092b3919b3ca8
kvmtool	stack/kvmtool	https://git.gitlab.arm.com/linux-arm/kvmtool-cca	bcbb8d2dbaf06dfe90581e339343422cebad04bd
linux	stack/linux	https://git.gitlab.arm.com/infra-solutions/reference-design/platsw/linux	e0e5ea70326d816308e5a03358835482a53d6e00
mbedtls	stack/mbedtls	https://github.com/ARMmbed/mbedtls.git	107ea89daaefb9867ea9121002fbbdf926780e98
model-scripts	stack/model-scripts	https://git.gitlab.arm.com/infra-solutions/reference-design/scripts/model-scripts	764298dfa5f79cfb9159a3201ba2f65e0b59c359
rmm	stack/rmm	https://git.gitlab.arm.com/infra-solutions/reference-design/platsw/tf-rmm	7efb3e0af62f619c355114d80ba48cbb0b13b905
scp	stack/scp	https://git.gitlab.arm.com/infra-solutions/reference-design/platsw/scp-firmware	08eb76121af4716386faed8c6524664d994f7129
tf-a	stack/tf-a	https://git.gitlab.arm.com/infra-solutions/reference-design/platsw/trusted-firmware-a	a4b376b128bb5b91771002f7808566f53c8d9f3a
tf-m	stack/tf-m	https://git.gitlab.arm.com/infra-solutions/reference-design/platsw/trusted-firmware-m	2c1ffad021790eca77b7e0105223475441907e87
tools-acpica	stack/tools/acpica	https://github.com/acpica/acpica	170fc3076a86777077637f10b05c32ac21ac13aa
tools-efitools	stack/tools/efitools	https://git.kernel.org/pub/scm/linux/kernel/git/jejb/efitools	392836a46ce3c92b55dc88a1aebbcfdfc5dcddce
uefi-edk2	stack/uefi/edk2	https://git.gitlab.arm.com/infra-solutions/reference-design/platsw/edk2	dd25905d63ec72d6e06804155fda1098d10da19e
uefi-edk2-platforms	stack/uefi/edk2-platforms	https://git.gitlab.arm.com/infra-solutions/reference-design/platsw/edk2-platforms	d504fc6d655d4cc07687eee02c668ccaadfe85ce
kvm-unit-tests	stack/validation/sys-test/kvm-unit-tests	https://git.gitlab.arm.com/infra-solutions/reference-design/valsw/kvm-unit-tests	b3e4f17eda04e6f2ae3419c3060064af1ef81b70
SUBMODULES
