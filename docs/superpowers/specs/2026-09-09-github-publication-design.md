# GitHub Publication Design

## Goal

Publish the local `arm-fvp` repository to
`git@github.com:buzhidaojiaoshenm/arm-fvp.git` so a new Linux environment can
clone the repository and follow a clear, reproducible install, build, and run
workflow.

## Publication Boundary

The repository will contain the orchestration scripts, compatibility patches,
tests, and documentation needed to reproduce the workspace. It will not
contain generated or licensed inputs:

- Arm FVP archives (`*.tgz`)
- installed proprietary FVP models (`models/`)
- the synced and generated RD-INFRA tree (`stack/`)
- logs (`logs/`)
- downloaded helper tools (`.tools/`)

These paths remain covered by `.gitignore`. Users must obtain the two Arm FVP
11.29.35 archives themselves, accept Arm's EULA, and place the archives at the
repository root before running the installer wrapper.

## Git and Branch Strategy

The empty GitHub repository will use `main` as its published branch. The local
`master` branch will be renamed to `main`, an `origin` SSH remote will be added,
and the branch will be pushed with upstream tracking. Because the host's global
SSH configuration currently fails its permission check, this repository will
use `ssh -F /dev/null` through a repository-local `core.sshCommand` setting.

## README

The existing untracked `Readme` content will become `README.md`. Its opening
section will provide:

1. host prerequisites and memory expectations;
2. the required proprietary archive names and EULA caveat;
3. clone, install, sync, build, and run commands;
4. pointers to the detailed runbook and architecture explanation.

The README must not imply that cloning alone downloads or licenses the FVP
model.

## Run Modes

The checked-in run wrappers will retain automated boot validation as the
default behavior. They will run headlessly, wait for `buildroot login`, stop
the model, and return success.

The RD-V3-R1 wrapper will also support an explicit interactive mode. This
preserves the intent of the current uncommitted launcher edit without changing
the documented default or breaking the existing validation test. The README
will describe both modes. RD-V3-R1-Cfg1 remains validation-only unless an
interactive mode is separately requested.

## Existing Untracked Documentation

The two existing proxy-test design and implementation-plan documents will be
included. They describe an already-landed test correction and contain no
generated binaries or credentials.

## Verification

Before publication:

- run every tracked `tests/test_*.sh` test;
- run `git diff --check`;
- inspect the staged file list and object sizes;
- confirm ignored archives, models, stack sources/build products, and logs are
  absent from the commit;
- scan tracked filenames and content for common credential patterns.

After publication, clone the GitHub repository into a temporary directory and
confirm:

- the default branch is `main`;
- the expected scripts, patches, tests, and README are present;
- generated/licensed directories and archives are absent;
- the lightweight tests that do not require local models or a generated stack
  pass from the fresh clone.
