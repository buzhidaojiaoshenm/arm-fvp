# RD-INFRA Submodule Layout Design

## Goal

Replace the ignored `repo`-managed `stack/` workspace with Git submodules
pinned to the exact commits used by `RD-INFRA-2025.07.03`, while retaining the
repository's local compatibility changes as reproducible top-level patches.
Fix the root README so tables render correctly on GitHub and the clone/setup
instructions match the submodule workflow.

## Scope

The parent repository will track source repositories as Git submodule links.
It will not track:

- Arm FVP installer archives or installed proprietary models;
- `.repo` metadata from the current Google Repo workspace;
- build outputs, downloaded toolchains, caches, logs, or generated images;
- the locally modified TF-M `bl1_dummy_rotpk.prv` private-key file.

Submodules will point directly to their public upstream repositories. A clone
therefore depends on those upstream services remaining accessible. Mirroring
the repositories into the GitHub account is outside this design.

## Submodule Map

All submodules are pinned by the parent repository's Git links, not by a
floating branch.

| Parent path | Upstream repository | Commit |
| --- | --- | --- |
| `stack/build-scripts` | `https://git.gitlab.arm.com/infra-solutions/reference-design/scripts/build-scripts` | `39a69c81a8bbaf7dd90e472bedf759cb2d1a9ff5` |
| `stack/buildroot` | `https://git.gitlab.arm.com/infra-solutions/reference-design/platsw/buildroot` | `bb43b43528dbdf517dce9a582b897a1b4883e7d4` |
| `stack/busybox` | `https://github.com/mirror/busybox` | `1a64f6a20aaf6ea4dbba68bbfa8cc1ab7e5c57c4` |
| `stack/container-scripts` | `https://git.gitlab.arm.com/infra-solutions/reference-design/scripts/container-scripts` | `7c67d3942bb0c392011e96b74022d03577ac76c9` |
| `stack/grub` | `https://git.savannah.gnu.org/git/grub.git` | `2a2e10c1b39672de3d5da037a50d5c371f49b40d` |
| `stack/hafnium` | `https://git.trustedfirmware.org/hafnium/hafnium.git` | `bd2fc0e099a19a8af300d36cb3d092b3919b3ca8` |
| `stack/kvmtool` | `https://git.gitlab.arm.com/linux-arm/kvmtool-cca` | `bcbb8d2dbaf06dfe90581e339343422cebad04bd` |
| `stack/linux` | `https://git.gitlab.arm.com/infra-solutions/reference-design/platsw/linux` | `e0e5ea70326d816308e5a03358835482a53d6e00` |
| `stack/mbedtls` | `https://github.com/ARMmbed/mbedtls.git` | `107ea89daaefb9867ea9121002fbbdf926780e98` |
| `stack/model-scripts` | `https://git.gitlab.arm.com/infra-solutions/reference-design/scripts/model-scripts` | `764298dfa5f79cfb9159a3201ba2f65e0b59c359` |
| `stack/rmm` | `https://git.gitlab.arm.com/infra-solutions/reference-design/platsw/tf-rmm` | `7efb3e0af62f619c355114d80ba48cbb0b13b905` |
| `stack/scp` | `https://git.gitlab.arm.com/infra-solutions/reference-design/platsw/scp-firmware` | `08eb76121af4716386faed8c6524664d994f7129` |
| `stack/tf-a` | `https://git.gitlab.arm.com/infra-solutions/reference-design/platsw/trusted-firmware-a` | `a4b376b128bb5b91771002f7808566f53c8d9f3a` |
| `stack/tf-m` | `https://git.gitlab.arm.com/infra-solutions/reference-design/platsw/trusted-firmware-m` | `2c1ffad021790eca77b7e0105223475441907e87` |
| `stack/tools/acpica` | `https://github.com/acpica/acpica` | `170fc3076a86777077637f10b05c32ac21ac13aa` |
| `stack/tools/efitools` | `https://git.kernel.org/pub/scm/linux/kernel/git/jejb/efitools` | `392836a46ce3c92b55dc88a1aebbcfdfc5dcddce` |
| `stack/uefi/edk2` | `https://git.gitlab.arm.com/infra-solutions/reference-design/platsw/edk2` | `dd25905d63ec72d6e06804155fda1098d10da19e` |
| `stack/uefi/edk2-platforms` | `https://git.gitlab.arm.com/infra-solutions/reference-design/platsw/edk2-platforms` | `d504fc6d655d4cc07687eee02c668ccaadfe85ce` |
| `stack/validation/sys-test/kvm-unit-tests` | `https://git.gitlab.arm.com/infra-solutions/reference-design/valsw/kvm-unit-tests` | `b3e4f17eda04e6f2ae3419c3060064af1ef81b70` |

The `.gitmodules` entries will ignore untracked files when the parent reports
submodule status. This prevents normal in-tree build products from making the
parent repository permanently dirty while still reporting tracked changes.

## EDK2 Platforms Assembly

The current Repo manifest checks `edk2-platforms` out inside the `edk2`
working tree. A parent Git repository cannot track a submodule below another
submodule's Git link. Therefore:

1. `edk2` is checked out at `stack/uefi/edk2`;
2. `edk2-platforms` is checked out beside it at
   `stack/uefi/edk2-platforms`;
3. the setup script creates
   `stack/uefi/edk2/edk2-platforms -> ../edk2-platforms`;
4. the setup script records the generated link in the `edk2` worktree's local
   exclude file, resolved with `git rev-parse --git-path info/exclude`, so it
   does not appear as an unrelated untracked file.

This preserves the path expected by `build-uefi.sh` without forking either
upstream repository. If the existing local Repo workspace already contains a
real nested `edk2-platforms` checkout at the pinned commit, setup preserves it
instead of replacing it; fresh submodule clones receive the link.

## Local Modification Preservation

The submodule links remain pinned to clean upstream commits. Intentional local
changes are represented as top-level patches and applied idempotently by
`scripts/apply-rdinfra-fixes.sh`:

| Submodule | Preserved change | Patch |
| --- | --- | --- |
| `container-scripts` | proxy build arguments and resilient Clang download | existing `container-proxy.patch` |
| `model-scripts` | corrected shared helper path | existing `model-script-helper-path.patch` |
| `build-scripts` | Buildroot `util-linux` binaries and `numactl` packages | new patch |
| `validation/sys-test/kvm-unit-tests` | six PMU counters for realm tests | new patch |

The TF-M private-key change is not preserved. Submodule initialization restores
the public upstream dummy-key version, and any build-generated key change stays
local and untracked by the parent repository.

## Setup Workflow

`scripts/sync-rdinfra-stack.sh` keeps its public entry-point name but changes
responsibility. It will:

1. run `git submodule sync --recursive`;
2. initialize and update all submodules to the parent-pinned commits, using
   shallow fetches where supported and retrying without `--depth` if an
   upstream cannot serve a pinned commit shallowly;
3. create the `edk2-platforms` compatibility link;
4. apply all four local patches idempotently.

Users can either clone with submodules immediately:

```bash
git clone --recurse-submodules --shallow-submodules \
  git@github.com:buzhidaojiaoshenm/arm-fvp.git
```

or run `bash scripts/sync-rdinfra-stack.sh` after an ordinary clone.

## README Rendering

The four terminal-style data tables in `README.md` will become GitHub-flavored
Markdown tables. Architecture diagrams, boot sequences, and directory trees
will be fenced as text code blocks so spacing and connector characters render
consistently. The quick-start text will describe submodule initialization and
will continue to state that FVP archives are not redistributed.

## Verification

Automated checks will verify:

- all 19 `.gitmodules` entries, URLs, paths, and pinned Git links;
- no `.repo`, FVP archive, model, output, cache, log, or generated-key content
  is tracked by the parent;
- the setup script is syntactically valid and patch application is idempotent;
- the `edk2-platforms` assembly link resolves to the sibling submodule;
- README tables use valid Markdown delimiters and terminal diagrams are fenced;
- all existing repository shell tests pass against the converted local
  workspace;
- a fresh recursive clone checks out every expected submodule commit and can
  run the setup checks without downloading the FVP archives.
