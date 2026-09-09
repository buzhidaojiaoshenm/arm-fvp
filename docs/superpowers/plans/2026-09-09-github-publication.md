# GitHub Publication Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish a tested, documented, lightweight `arm-fvp` repository to GitHub with an explicit interactive RD-V3-R1 run mode and a reproducible first-clone workflow.

**Architecture:** Git tracks only orchestration code, patches, tests, and documentation; licensed FVP inputs and generated RD-INFRA state remain ignored. The existing RD-V3-R1 wrapper keeps automated validation as its default and selects persistent interactive execution only when `--interactive` is supplied. GitHub receives a renamed `main` branch over an SSH command that bypasses the broken host-global SSH configuration.

**Tech Stack:** Bash, Git, GitHub SSH transport, Arm RD-INFRA wrapper scripts, Markdown

---

### Task 1: Preserve Default Validation and Add Explicit Interactive Mode

**Files:**
- Modify: `tests/test_rdv3r1_boot_prereq.sh`
- Modify: `scripts/run-rdv3r1.sh`

- [ ] **Step 1: Extend the static launcher test so it requires both modes**

Keep the existing checks and replace the last wrapper assertion with exact-line checks for the validation and interactive commands, plus a check for the interactive argument:

```bash
grep -Fq -- '--interactive' "$wrapper"
grep -Fxq '    MODEL="$model" ./boot-buildroot.sh -p rdv3r1' "$wrapper"
grep -Fxq '    MODEL="$model" ./boot-buildroot.sh -p rdv3r1 -j -t' "$wrapper"
```

- [ ] **Step 2: Run the focused test and verify that the current launcher fails it**

Run `bash tests/test_rdv3r1_boot_prereq.sh`.

Expected: non-zero exit because the current uncommitted wrapper has no
`--interactive` argument parser and no automated validation branch.

- [ ] **Step 3: Implement minimal run-mode selection**

After finding the model, accept either no argument or `--interactive`; reject
anything else with exit status 2. Use this selection after changing to the
model-script directory:

```bash
case ${1:-} in
    '') interactive=false ;;
    --interactive) interactive=true ;;
    *)
        printf 'Usage: %s [--interactive]\n' "${0##*/}" >&2
        exit 2
        ;;
esac

if [[ $interactive == true ]]; then
    MODEL="$model" ./boot-buildroot.sh -p rdv3r1
else
    MODEL="$model" ./boot-buildroot.sh -p rdv3r1 -j -t
fi
```

- [ ] **Step 4: Run focused checks**

Run:

```bash
bash -n scripts/run-rdv3r1.sh
bash tests/test_rdv3r1_boot_prereq.sh
git diff --check
```

Expected: all commands exit 0.

- [ ] **Step 5: Commit the launcher change**

```bash
git add scripts/run-rdv3r1.sh tests/test_rdv3r1_boot_prereq.sh
git commit -m "feat: add interactive RD-V3-R1 run mode"
```

### Task 2: Publish the First-Clone Workflow

**Files:**
- Rename: `Readme` to `README.md`
- Modify: `README.md`
- Modify: `docs/rdv3r1-fvp-runbook.md`
- Add: `docs/superpowers/specs/2026-08-24-proxy-build-arg-test-design.md`
- Add: `docs/superpowers/plans/2026-08-24-proxy-build-arg-test.md`

- [ ] **Step 1: Rename the root documentation file**

Run `mv Readme README.md`.

- [ ] **Step 2: Add the quick-start section before the detailed Chinese architecture explanation**

The new opening must state:

```markdown
# arm-fvp

Reproducible wrappers for Arm RD-V3-R1 and RD-V3-R1-Cfg1 FVP 11.29.35 with
the pinned RD-INFRA-2025.07.03 software stack.

## Important licensing boundary

This repository does not redistribute Arm's proprietary FVP archives or
installed model binaries. Obtain the archives from Arm, review and accept the
contained EULA, then copy these files to the repository root:

- `FVP_RD_V3_R1_11.29_35_Linux64.tgz`
- `FVP_RD_V3_R1_Cfg1_11.29_35_Linux64.tgz`
```

Follow it with prerequisites, clone, install, sync, build, automated run, and
`bash scripts/run-rdv3r1.sh --interactive` commands. Retain the existing
detailed Chinese flow below a `## Detailed build and boot flow` heading.

- [ ] **Step 3: Document both RD-V3-R1 modes in the runbook**

Keep the existing automated run command and add:

```bash
bash scripts/run-rdv3r1.sh --interactive
```

Explain that the default uses `-j -t` and exits after `buildroot login`, while
interactive mode leaves the model running and delegates console behavior to
the upstream model script.

- [ ] **Step 4: Run documentation and formatting checks**

Run:

```bash
bash tests/test_fvp_runbook.sh
git diff --check
```

Expected: both commands exit 0 and `README.md` names the two required archives,
all six workflow wrappers, and the interactive command.

- [ ] **Step 5: Commit the publication documentation**

```bash
git add README.md docs/rdv3r1-fvp-runbook.md \
  docs/superpowers/specs/2026-08-24-proxy-build-arg-test-design.md \
  docs/superpowers/plans/2026-08-24-proxy-build-arg-test.md \
  docs/superpowers/plans/2026-09-09-github-publication.md
git commit -m "docs: add GitHub clone and run guide"
```

### Task 3: Verify the Publication Set

**Files:**
- Inspect: all tracked files

- [ ] **Step 1: Run the repository shell suite**

Run `for test in tests/test_*.sh; do bash "$test"; done`.

Expected: every test exits 0 using the populated local models and stack.

- [ ] **Step 2: Check formatting and repository state**

Run:

```bash
git diff --check
git status --short
```

Expected: no output.

- [ ] **Step 3: Inspect the tracked publication boundary**

Run:

```bash
git ls-files
git ls-files '*.tgz' 'models/**' 'stack/**' 'logs/**' '.tools/**'
git count-objects -vH
```

Expected: the second command prints nothing and repository objects remain
small enough for a normal GitHub push.

- [ ] **Step 4: Scan tracked content for common secret forms**

Run:

```bash
git grep -nEI '(BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|github_[p]at_|ghp_[A-Za-z0-9]|AKIA[0-9A-Z]{16})'
```

Expected: exit status 1 with no matches.

### Task 4: Configure and Push GitHub Main

**Files:**
- Modify: repository-local Git configuration and branch refs only

- [ ] **Step 1: Rename the branch and configure SSH transport**

Run:

```bash
git branch -m master main
git config core.sshCommand 'ssh -F /dev/null'
git remote add origin git@github.com:buzhidaojiaoshenm/arm-fvp.git
```

Expected: `git branch --show-current` prints `main`, and `git remote -v` shows
the requested GitHub SSH URL.

- [ ] **Step 2: Push and establish upstream tracking**

Run `git push -u origin main`.

Expected: GitHub accepts the objects and local `main` tracks `origin/main`.

### Task 5: Verify a Fresh Remote Clone

**Files:**
- Create temporarily: a directory below `/tmp`

- [ ] **Step 1: Clone the published repository into a temporary directory**

Run:

```bash
verification_root=$(mktemp -d /tmp/arm-fvp-github-verify.XXXXXX)
git -c core.sshCommand='ssh -F /dev/null' clone \
  git@github.com:buzhidaojiaoshenm/arm-fvp.git "$verification_root/arm-fvp"
```

Expected: clone succeeds and checks out `main`.

- [ ] **Step 2: Validate clone contents and boundary**

From the clone, verify `README.md`, scripts, tests, and patches exist; verify
`*.tgz`, `models/`, `stack/`, `logs/`, and `.tools/` do not exist.

- [ ] **Step 3: Run lightweight clone-safe checks**

Run:

```bash
bash tests/test_fvp_runbook.sh
bash -n scripts/install-fvps.sh
grep -Fq 'FVP_RD_V3_R1_11.29_35_Linux64.tgz' scripts/install-fvps.sh
grep -Fq 'FVP_RD_V3_R1_Cfg1_11.29_35_Linux64.tgz' scripts/install-fvps.sh
```

Expected: the runbook test and static installer checks exit 0 without requiring
licensed archives, installed models, or a generated stack.
