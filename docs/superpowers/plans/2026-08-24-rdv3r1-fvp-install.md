# RD-V3-R1 FVP Installation and Boot Implementation Plan

> For agentic workers: REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking.

Goal: Install the supplied RD-V3-R1 and RD-V3-R1-Cfg1 FVPs and boot Arm's pinned Buildroot software stack on both models.

Architecture: Both vendor models are installed under workspace-local prefixes. A single repo checkout at Arm's RD-INFRA-2025.07.03 tag produces separate platform artifacts; Arm's model scripts boot each image using its matching FVP. Tracked wrappers make every operation repeatable while archives, models, sources, and logs remain ignored.

Tech Stack: FVP 11.29.35, Arm RD-INFRA-2025.07.03, Google repo, Docker, Buildroot.

---

### Task 1: Protect generated state and validate the host

Files:
- Create: .gitignore
- Create: docs/rdv3r1-fvp-preflight.md

- [ ] Step 1: Add source-only ignore rules.

    *.tgz
    .tools/
    models/
    stack/
    logs/

- [ ] Step 2: Check the ignore rules.

    Run: git check-ignore -v FVP_RD_V3_R1_11.29_35_Linux64.tgz models/rdv3r1 stack logs
    Expected: every argument is ignored.

- [ ] Step 3: Create docs/rdv3r1-fvp-preflight.md containing the date, uname -m, PRETTY_NAME, df -h ., SHA-256 for each archive, Docker client/server versions, and the release pair FVP 11.29.35 / RD-INFRA-2025.07.03.

- [ ] Step 4: Verify Docker daemon access.

    Run: docker version --format '{{.Client.Version}} {{.Server.Version}}'
    Expected: client and server versions. If daemon access fails, stop before source sync; do not use an unaudited replacement runtime.

- [ ] Step 5: Commit reproducibility metadata.

    git add .gitignore docs/rdv3r1-fvp-preflight.md
    git diff --check --cached
    git commit -m "docs: record RD-V3-R1 FVP preflight"

### Task 2: Install both FVPs in workspace-local prefixes

Files:
- Create: scripts/install-fvps.sh
- Create: tests/test_install_fvps.sh
- Generated: models/rdv3r1/
- Generated: models/rdv3r1-cfg1/

- [ ] Step 1: Write the failing installer test in tests/test_install_fvps.sh.

    #!/usr/bin/env bash
    set -euo pipefail
    root=$(cd "$(dirname "$0")/.." && pwd)
    find "$root/models/rdv3r1/models" -type f -name FVP_RD_V3_R1 -executable | grep -q .
    find "$root/models/rdv3r1-cfg1/models" -type f -name FVP_RD_V3_R1_Cfg1 -executable | grep -q .

- [ ] Step 2: Establish the red test.

    Run: bash tests/test_install_fvps.sh
    Expected: nonzero status because neither model is installed.

- [ ] Step 3: Implement the local non-interactive installer as scripts/install-fvps.sh.

    #!/usr/bin/env bash
    set -euo pipefail
    root=$(cd "$(dirname "$0")/.." && pwd)
    stage=$(mktemp -d)
    trap 'rm -rf "$stage"' EXIT

    install_fvp() {
        local archive=$1 installer=$2 destination=$3
        tar -xzf "$root/$archive" -C "$stage" "$installer"
        sh "$stage/$installer" --no-interactive --i-agree-to-the-contained-eula \
            --force --destination "$destination"
    }

    install_fvp FVP_RD_V3_R1_11.29_35_Linux64.tgz FVP_RD_V3_R1.sh "$root/models/rdv3r1"
    install_fvp FVP_RD_V3_R1_Cfg1_11.29_35_Linux64.tgz FVP_RD_V3_R1_Cfg1.sh "$root/models/rdv3r1-cfg1"

The command must not be run until the user explicitly accepts both bundled Arm EULAs, because the option asserts acceptance.

- [ ] Step 4: Install and prove both models.

    bash scripts/install-fvps.sh
    bash tests/test_install_fvps.sh
    find models -type f \( -name FVP_RD_V3_R1 -o -name FVP_RD_V3_R1_Cfg1 \) -executable -print

    Expected: installer and test exit 0; the final command prints one executable per model.

- [ ] Step 5: Commit tracked installer tooling only.

    git add scripts/install-fvps.sh tests/test_install_fvps.sh
    git diff --check --cached
    git commit -m "build: add local FVP installer"

### Task 3: Fetch Arm's release-pinned software stack

Files:
- Create: scripts/sync-rdinfra-stack.sh
- Create: tests/test_stack_manifest.sh
- Generated: .tools/bin/repo
- Generated: stack/

- [ ] Step 1: Write the failing source-sync test in tests/test_stack_manifest.sh.

    #!/usr/bin/env bash
    set -euo pipefail
    root=$(cd "$(dirname "$0")/.." && pwd)
    test -f "$root/stack/.repo/manifest.xml"
    grep -Fq 'RD-INFRA-2025.07.03' "$root/stack/.repo/manifest.xml"
    test -d "$root/stack/build-scripts"
    test -d "$root/stack/model-scripts"

- [ ] Step 2: Establish the red test.

    Run: bash tests/test_stack_manifest.sh
    Expected: nonzero status because the manifest is absent.

- [ ] Step 3: Implement exact manifest sync as scripts/sync-rdinfra-stack.sh.

    #!/usr/bin/env bash
    set -euo pipefail
    root=$(cd "$(dirname "$0")/.." && pwd)
    repo_bin="$root/.tools/bin/repo"
    mkdir -p "$(dirname "$repo_bin")" "$root/stack"
    if [ ! -x "$repo_bin" ]; then
        curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo -o "$repo_bin"
        chmod 0755 "$repo_bin"
    fi
    cd "$root/stack"
    if [ ! -d .repo ]; then
        "$repo_bin" init \
            -u https://git.gitlab.arm.com/infra-solutions/reference-design/infra-refdesign-manifests.git \
            -m pinned-rdv3r1.xml \
            -b refs/tags/RD-INFRA-2025.07.03 \
            --depth=1
    fi
    "$repo_bin" sync -c -j "$(nproc)" --fetch-submodules --force-sync --no-clone-bundle

- [ ] Step 4: Sync and validate.

    bash scripts/sync-rdinfra-stack.sh
    bash tests/test_stack_manifest.sh

    Expected: both commands exit 0; manifest, build-scripts, and model-scripts exist.

- [ ] Step 5: Commit sync tooling.

    git add scripts/sync-rdinfra-stack.sh tests/test_stack_manifest.sh
    git diff --check --cached
    git commit -m "build: add pinned RD infrastructure sync"

### Task 4: Build and boot RD-V3-R1

Files:
- Create: scripts/build-rdv3r1.sh
- Create: scripts/run-rdv3r1.sh
- Create: tests/test_rdv3r1_artifacts.sh
- Generated: logs/rdv3r1/
- Generated: stack/output/rdv3r1/

- [ ] Step 1: Write the failing artifact test in tests/test_rdv3r1_artifacts.sh.

    #!/usr/bin/env bash
    set -euo pipefail
    root=$(cd "$(dirname "$0")/.." && pwd)
    test -e "$root/stack/output/rdv3r1/rdv3r1/fip-uefi.bin"
    test -e "$root/stack/output/rdv3r1/rdv3r1/Image"

- [ ] Step 2: Establish the red test.

    Run: bash tests/test_rdv3r1_artifacts.sh
    Expected: nonzero status because packaged firmware is absent.

- [ ] Step 3: Create scripts/build-rdv3r1.sh.

    #!/usr/bin/env bash
    set -euo pipefail
    root=$(cd "$(dirname "$0")/.." && pwd)
    cd "$root/stack/container-scripts"
    ./container.sh build
    docker run --rm \
      -v "$root/stack:$root/stack" -w "$root/stack" \
      --mount type=volume,dst="$HOME" \
      --env ARCADE_USER="$(id -un)" --env ARCADE_UID="$(id -u)" --env ARCADE_GID="$(id -g)" \
      -t -i rdinfra-builder \
      bash -c './build-scripts/rdinfra/build-test-buildroot.sh -p rdv3r1 build && \
               ./build-scripts/rdinfra/build-test-buildroot.sh -p rdv3r1 package'

- [ ] Step 4: Build/package and prove artifacts.

    mkdir -p logs/rdv3r1
    bash scripts/build-rdv3r1.sh |& tee logs/rdv3r1/build.log
    bash tests/test_rdv3r1_artifacts.sh

    Expected: both commands exit 0.

- [ ] Step 5: Create scripts/run-rdv3r1.sh and boot.

    #!/usr/bin/env bash
    set -euo pipefail
    root=$(cd "$(dirname "$0")/.." && pwd)
    model=$(find "$root/models/rdv3r1/models" -type f -name FVP_RD_V3_R1 -executable -print -quit)
    test -n "$model"
    cd "$root/stack/model-scripts/rdinfra"
    MODEL="$model" ./boot-buildroot.sh -p rdv3r1

    Run: bash scripts/run-rdv3r1.sh
    Expected: model logs under stack/model-scripts/rdinfra/platforms/rdv3r1/rdv3r1/ reach a Buildroot login or shell prompt.

- [ ] Step 6: Commit workflow.

    git add scripts/build-rdv3r1.sh scripts/run-rdv3r1.sh tests/test_rdv3r1_artifacts.sh
    git diff --check --cached
    git commit -m "build: add RD-V3-R1 boot workflow"

### Task 5: Build and boot RD-V3-R1-Cfg1

Files:
- Create: scripts/build-rdv3r1-cfg1.sh
- Create: scripts/run-rdv3r1-cfg1.sh
- Create: tests/test_rdv3r1_cfg1_artifacts.sh
- Generated: logs/rdv3r1-cfg1/
- Generated: stack/output/rdv3r1cfg1/

- [ ] Step 1: Confirm the pinned Cfg1 key.

    Run: rg -n 'rdv3r1.*cfg1|rdv3r1cfg1' stack/build-scripts stack/model-scripts
    Expected: the stack identifies the key used below, rdv3r1cfg1. If it differs, use the printed key consistently and record it in the runbook.

- [ ] Step 2: Write and run the failing Cfg1 artifact test in tests/test_rdv3r1_cfg1_artifacts.sh.

    #!/usr/bin/env bash
    set -euo pipefail
    root=$(cd "$(dirname "$0")/.." && pwd)
    test -e "$root/stack/output/rdv3r1cfg1/rdv3r1cfg1/fip-uefi.bin"
    test -e "$root/stack/output/rdv3r1cfg1/rdv3r1cfg1/Image"

    Run: bash tests/test_rdv3r1_cfg1_artifacts.sh
    Expected: nonzero status because Cfg1 package does not exist.

- [ ] Step 3: Create scripts/build-rdv3r1-cfg1.sh.

    #!/usr/bin/env bash
    set -euo pipefail
    root=$(cd "$(dirname "$0")/.." && pwd)
    cd "$root/stack/container-scripts"
    ./container.sh build
    docker run --rm \
      -v "$root/stack:$root/stack" -w "$root/stack" \
      --mount type=volume,dst="$HOME" \
      --env ARCADE_USER="$(id -un)" --env ARCADE_UID="$(id -u)" --env ARCADE_GID="$(id -g)" \
      -t -i rdinfra-builder \
      bash -c './build-scripts/rdinfra/build-test-buildroot.sh -p rdv3r1cfg1 build && \
               ./build-scripts/rdinfra/build-test-buildroot.sh -p rdv3r1cfg1 package'

- [ ] Step 4: Create scripts/run-rdv3r1-cfg1.sh.

    #!/usr/bin/env bash
    set -euo pipefail
    root=$(cd "$(dirname "$0")/.." && pwd)
    model=$(find "$root/models/rdv3r1-cfg1/models" -type f -name FVP_RD_V3_R1_Cfg1 -executable -print -quit)
    test -n "$model"
    cd "$root/stack/model-scripts/rdinfra"
    MODEL="$model" ./boot-buildroot.sh -p rdv3r1cfg1

- [ ] Step 5: Build, package, and boot Cfg1.

    mkdir -p logs/rdv3r1-cfg1
    bash scripts/build-rdv3r1-cfg1.sh |& tee logs/rdv3r1-cfg1/build.log
    bash tests/test_rdv3r1_cfg1_artifacts.sh
    bash scripts/run-rdv3r1-cfg1.sh

    Expected: build and test exit 0 and the FVP log reaches a Buildroot login or shell prompt.

- [ ] Step 6: Commit Cfg1 workflow.

    git add scripts/build-rdv3r1-cfg1.sh scripts/run-rdv3r1-cfg1.sh tests/test_rdv3r1_cfg1_artifacts.sh
    git diff --check --cached
    git commit -m "build: add RD-V3-R1-Cfg1 boot workflow"

### Task 6: Record final evidence and handoff

Files:
- Create: docs/rdv3r1-fvp-runbook.md
- Create: tests/test_fvp_runbook.sh

- [ ] Step 1: Write tests/test_fvp_runbook.sh.

    #!/usr/bin/env bash
    set -euo pipefail
    root=$(cd "$(dirname "$0")/.." && pwd)
    for file in install-fvps sync-rdinfra-stack build-rdv3r1 run-rdv3r1 build-rdv3r1-cfg1 run-rdv3r1-cfg1; do
        test -x "$root/scripts/$file.sh"
    done
    grep -Fq 'RD-INFRA-2025.07.03' "$root/docs/rdv3r1-fvp-runbook.md"
    grep -Fq 'Buildroot' "$root/docs/rdv3r1-fvp-runbook.md"

- [ ] Step 2: Create docs/rdv3r1-fvp-runbook.md documenting the six wrappers, model paths, the Arm release tag, Docker requirement, expected Buildroot login marker, model log paths, and Ubuntu 26.04 best-effort support. Do not add archives or generated logs to Git.

- [ ] Step 3: Verify the tracked workflow and commit.

    chmod 0755 scripts/*.sh tests/*.sh
    bash tests/test_install_fvps.sh
    bash tests/test_stack_manifest.sh
    bash tests/test_rdv3r1_artifacts.sh
    bash tests/test_rdv3r1_cfg1_artifacts.sh
    bash tests/test_fvp_runbook.sh
    git diff --check
    git status --short

    Expected: all tests exit 0, git diff --check is empty, and archives/models/stack/logs are ignored.

    git add docs/rdv3r1-fvp-runbook.md tests/test_fvp_runbook.sh
    git diff --check --cached
    git commit -m "docs: add RD-V3-R1 FVP runbook"
