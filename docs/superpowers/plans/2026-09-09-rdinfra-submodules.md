# RD-INFRA Submodules Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Track the pinned RD-INFRA source repositories as Git submodules, replay the local stack fixes reproducibly, and make the README render correctly on GitHub.

**Architecture:** The parent repository records 19 upstream Git links at exact commits and keeps generated data out of its history. Top-level patches reproduce four intentional local source changes; the setup wrapper initializes submodules, assembles the special EDK2 layout, and applies those patches. The existing local Repo workspace is preserved in place while a fresh clone uses normal Git submodule metadata.

**Tech Stack:** Git submodules, Bash, GitHub-flavored Markdown, Arm RD-INFRA 2025.07.03

---

### Task 1: Record the 19-Repository Submodule Topology

**Files:**
- Create: `.gitmodules`
- Modify: `.gitignore`
- Modify: `tests/test_stack_manifest.sh`
- Track: 19 Git links below `stack/`

- [ ] **Step 1: Replace the Repo-manifest test with a failing submodule test**

Write `tests/test_stack_manifest.sh` so it reads the following tab-separated
matrix and verifies each submodule name, path, URL, index mode `160000`, and
pinned SHA:

```text
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
```

For each row, use `git config -f .gitmodules --get` for `path`, `url`,
`shallow`, and `ignore`; use `git ls-files --stage` for mode and SHA. Assert
that exactly 19 `.gitmodules` paths exist.

- [ ] **Step 2: Run the test and verify RED**

Run `bash tests/test_stack_manifest.sh`.

Expected: failure because `.gitmodules` does not exist.

- [ ] **Step 3: Create `.gitmodules` with the exact matrix**

Create one section per row using this exact four-key shape, substituting the
name, path, and URL from the matrix:

```ini
[submodule "build-scripts"]
	path = stack/build-scripts
	url = https://git.gitlab.arm.com/infra-solutions/reference-design/scripts/build-scripts
	shallow = true
	ignore = untracked
```

- [ ] **Step 4: Narrow `.gitignore` from the whole stack to generated data**

Replace `stack` with:

```gitignore
/stack/.repo/
/stack/output/
/stack/venv-tf-m/
```

Keep `*.tgz`, `.tools/`, `models/`, and `logs` ignored.

- [ ] **Step 5: Create the sibling EDK2 Platforms checkout without touching the nested checkout**

Run:

```bash
git clone --no-hardlinks stack/uefi/edk2/edk2-platforms stack/uefi/edk2-platforms
git -C stack/uefi/edk2-platforms remote set-url origin \
  https://git.gitlab.arm.com/infra-solutions/reference-design/platsw/edk2-platforms
git -C stack/uefi/edk2-platforms checkout --detach d504fc6d655d4cc07687eee02c668ccaadfe85ce
```

Expected: the existing nested checkout remains unchanged and the sibling is
at `d504fc6`.

- [ ] **Step 6: Stage all Git links**

Run:

```bash
git add .gitmodules .gitignore tests/test_stack_manifest.sh
git add -f stack/build-scripts stack/buildroot stack/busybox \
  stack/container-scripts stack/grub stack/hafnium stack/kvmtool stack/linux \
  stack/mbedtls stack/model-scripts stack/rmm stack/scp stack/tf-a stack/tf-m \
  stack/tools/acpica stack/tools/efitools stack/uefi/edk2 \
  stack/uefi/edk2-platforms stack/validation/sys-test/kvm-unit-tests
```

- [ ] **Step 7: Verify GREEN and commit**

Run `bash tests/test_stack_manifest.sh` and `git diff --cached --check`.

Expected: all 19 matrix rows pass and the staged diff has no whitespace
errors. Commit with:

```bash
git commit -m "build: track RD-INFRA stack as submodules"
```

### Task 2: Preserve Intentional Local Stack Changes as Patches

**Files:**
- Create: `patches/rdinfra-2025.07.03/buildroot-packages.patch`
- Create: `patches/rdinfra-2025.07.03/kvm-unit-tests-pmu.patch`
- Modify: `scripts/apply-rdinfra-fixes.sh`
- Modify: `tests/test_container_proxy_build_args.sh`

- [ ] **Step 1: Add failing patch-preservation assertions**

Add checks that both new patch files exist and that
`scripts/apply-rdinfra-fixes.sh` references `stack/build-scripts`,
`buildroot-packages.patch`, `stack/validation/sys-test/kvm-unit-tests`, and
`kvm-unit-tests-pmu.patch`. Also assert the populated local stack contains:

```text
BR2_PACKAGE_UTIL_LINUX_BINARIES=y
BR2_PACKAGE_NUMACTL=y
PMU_ARGS="--pmu --pmu-counters=6"
```

- [ ] **Step 2: Run the focused test and verify RED**

Run `bash tests/test_container_proxy_build_args.sh`.

Expected: failure because the two top-level patch files do not exist.

- [ ] **Step 3: Create the Buildroot package patch**

Create `patches/rdinfra-2025.07.03/buildroot-packages.patch`:

```diff
diff --git a/configs/rdv3r1/buildroot/aarch64_rdinfra_defconfig b/configs/rdv3r1/buildroot/aarch64_rdinfra_defconfig
index a5a20c2..2e828a9 100644
--- a/configs/rdv3r1/buildroot/aarch64_rdinfra_defconfig
+++ b/configs/rdv3r1/buildroot/aarch64_rdinfra_defconfig
@@ -14,7 +14,9 @@ BR2_PACKAGE_KVMTOOL=y
 BR2_PACKAGE_DMIDECODE=y
 BR2_PACKAGE_STRESS_NG=y
 BR2_PACKAGE_UTIL_LINUX=y
+BR2_PACKAGE_UTIL_LINUX_BINARIES=y
 BR2_PACKAGE_UTIL_LINUX_SCHEDUTILS=y
+BR2_PACKAGE_NUMACTL=y
```

- [ ] **Step 4: Create the realm-test PMU patch**

Create `patches/rdinfra-2025.07.03/kvm-unit-tests-pmu.patch`:

```diff
diff --git a/arm/run-realm-tests b/arm/run-realm-tests
index 839f2bf..0995f27 100755
--- a/arm/run-realm-tests
+++ b/arm/run-realm-tests
@@ -7,7 +7,7 @@
 TASKSET=${TASKSET:-taskset}
 LKVM=${LKVM:-lkvm}
 ARGS="--realm --restricted_mem --irqchip=gicv3 --console=serial --network mode=none --nodefaults --loglevel error"
-PMU_ARGS="--pmu --pmu-counters=8"
+PMU_ARGS="--pmu --pmu-counters=6"
```

- [ ] **Step 5: Apply both patches from the shared idempotent helper**

Append:

```bash
apply_once "$root/stack/build-scripts" \
    "$root/patches/rdinfra-2025.07.03/buildroot-packages.patch"
apply_once "$root/stack/validation/sys-test/kvm-unit-tests" \
    "$root/patches/rdinfra-2025.07.03/kvm-unit-tests-pmu.patch"
```

- [ ] **Step 6: Verify GREEN, idempotence, and commit**

Run:

```bash
bash scripts/apply-rdinfra-fixes.sh
bash scripts/apply-rdinfra-fixes.sh
bash tests/test_container_proxy_build_args.sh
git diff --check
```

Commit:

```bash
git add patches/rdinfra-2025.07.03 scripts/apply-rdinfra-fixes.sh \
  tests/test_container_proxy_build_args.sh
git commit -m "build: preserve local RD-INFRA stack fixes"
```

### Task 3: Replace Repo Sync with Submodule Setup

**Files:**
- Modify: `scripts/sync-rdinfra-stack.sh`
- Modify: `tests/test_stack_manifest.sh`

- [ ] **Step 1: Add failing setup assertions**

Require the setup wrapper to contain `git submodule sync --recursive`, a
shallow `git submodule update --init --recursive`, a non-shallow retry, the
`../edk2-platforms` link target, and the final `apply-rdinfra-fixes.sh` call.
Remove assertions referring to `.tools/bin/repo`, `.repo/manifest.xml`, and the
resolved Repo manifest hash.

- [ ] **Step 2: Run the test and verify RED**

Run `bash tests/test_stack_manifest.sh`.

Expected: failure because the current wrapper still uses Google Repo.

- [ ] **Step 3: Implement submodule initialization with one fallback**

Use:

```bash
cd "$repo_root"
git submodule sync --recursive
if ! git submodule update --init --recursive --depth=1 --jobs "$(nproc)"; then
    printf 'Shallow submodule update failed; retrying without --depth.\n' >&2
    git submodule update --init --recursive --jobs "$(nproc)"
fi
```

- [ ] **Step 4: Assemble EDK2 Platforms safely**

If `stack/uefi/edk2/edk2-platforms` is absent, create a symlink to
`../edk2-platforms`. If it is a symlink, require that exact target. If it is an
existing Git checkout, require its HEAD to equal the sibling checkout's HEAD.
Reject every other existing object. Resolve the exclude file with:

```bash
exclude_file=$(git -C "$repo_root/stack/uefi/edk2" rev-parse --git-path info/exclude)
grep -Fxq '/edk2-platforms' "$exclude_file" || printf '/edk2-platforms\n' >> "$exclude_file"
```

Finally call `bash "$repo_root/scripts/apply-rdinfra-fixes.sh"`.

- [ ] **Step 5: Verify syntax and local compatibility**

Run:

```bash
bash -n scripts/sync-rdinfra-stack.sh
bash tests/test_stack_manifest.sh
bash scripts/sync-rdinfra-stack.sh
bash tests/test_container_proxy_build_args.sh
bash tests/test_rdv3r1_boot_prereq.sh
```

Expected: the existing 15 GiB workspace remains intact and both EDK2 Platforms
checkouts resolve to `d504fc6`.

- [ ] **Step 6: Commit**

```bash
git add scripts/sync-rdinfra-stack.sh tests/test_stack_manifest.sh
git commit -m "build: initialize RD-INFRA through submodules"
```

### Task 4: Repair README Tables and Submodule Instructions

**Files:**
- Modify: `README.md`
- Modify: `docs/rdv3r1-fvp-runbook.md`
- Modify: `tests/test_fvp_runbook.sh`

- [ ] **Step 1: Add failing README rendering checks**

Require `README.md` to contain the recursive shallow clone command and at
least four Markdown header-separator rows containing `| ---`. Reject table
separator rows that start with whitespace followed by `━` or `─`.

- [ ] **Step 2: Run the documentation test and verify RED**

Run `bash tests/test_fvp_runbook.sh`.

Expected: failure because README still contains terminal-style table rows and
does not describe recursive submodule cloning.

- [ ] **Step 3: Convert the four data tables**

Convert these tables without changing their data:

1. synchronized directory and purpose;
2. RD-V3-R1 versus RD-V3-R1-Cfg1 parameters;
3. FIP entry and source;
4. image, FVP load location, and purpose.

Use standard GitHub Markdown:

```markdown
| 目录 | 内容 |
| --- | --- |
| `tf-m/` | RSE/TF-M 安全固件 |
```

- [ ] **Step 4: Fence diagrams and trees**

Wrap the overview flow, component build order, GPT tree, final output tree, and
boot sequence in fenced `text` blocks. Do not turn directory trees into data
tables.

- [ ] **Step 5: Update clone and synchronization prose**

Document:

```bash
git clone --recurse-submodules --shallow-submodules \
  git@github.com:buzhidaojiaoshenm/arm-fvp.git
cd arm-fvp
bash scripts/sync-rdinfra-stack.sh
```

Replace Google Repo descriptions with the pinned Git submodule workflow in
both README and runbook. Keep the warning that FVP archives are not included.

- [ ] **Step 6: Verify and commit**

Run `bash tests/test_fvp_runbook.sh` and `git diff --check`.

Commit:

```bash
git add README.md docs/rdv3r1-fvp-runbook.md tests/test_fvp_runbook.sh \
  docs/superpowers/plans/2026-09-09-rdinfra-submodules.md
git commit -m "docs: document the RD-INFRA submodule workflow"
```

### Task 5: Verify Locally, Push, and Verify a Fresh Recursive Clone

**Files:**
- Inspect: parent repository and all submodule Git links
- Create temporarily: clone below `/tmp`

- [ ] **Step 1: Run the full local suite**

Run:

```bash
for test in tests/test_*.sh; do bash "$test"; done
git diff --check
```

Expected: every test exits 0.

- [ ] **Step 2: Verify publication boundaries**

Require a clean parent status except for expected modified submodules caused by
the four replayed patches. Verify the parent tracks no `*.tgz`, `.repo`, model,
output, cache, log, or TF-M private-key file. Verify all 19 Git links use mode
`160000` and their index SHAs match the design.

- [ ] **Step 3: Push the verified parent commit**

Run `git push origin main`.

- [ ] **Step 4: Clone recursively from GitHub**

Run:

```bash
verify_root=$(mktemp -d /tmp/arm-fvp-submodules.XXXXXX)
git -c core.sshCommand='ssh -F /dev/null' clone --depth 1 \
  --recurse-submodules --shallow-submodules \
  git@github.com:buzhidaojiaoshenm/arm-fvp.git "$verify_root/arm-fvp"
```

- [ ] **Step 5: Run setup and clone-safe verification**

In the fresh clone, run `bash scripts/sync-rdinfra-stack.sh`, then run
`bash tests/test_stack_manifest.sh`, `bash tests/test_container_proxy_build_args.sh`,
`bash tests/test_rdv3r1_boot_prereq.sh`, and `bash tests/test_fvp_runbook.sh`.
Verify the EDK2 Platforms link points to `../edk2-platforms`, all 19 submodule
HEADs match their parent Git links, FVP archives are absent, and the parent
commit equals `origin/main`.

Expected: setup succeeds using the parent repository and configured submodule
upstreams without downloading any FVP archive.
