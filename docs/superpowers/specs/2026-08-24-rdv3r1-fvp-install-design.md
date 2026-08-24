# RD-V3-R1 and RD-V3-R1-Cfg1 FVP Installation Design

## Goal

Install the supplied Arm RD-V3-R1 and RD-V3-R1-Cfg1 FVP bundles in the workspace, obtain Arm's matching RD-INFRA-2025.07.03 platform software stack, and demonstrate a successful Buildroot boot on both platforms.

## Scope

The workspace is `/home/sjh/arm-fvp`. The two supplied archives are:

- `FVP_RD_V3_R1_11.29_35_Linux64.tgz`
- `FVP_RD_V3_R1_Cfg1_11.29_35_Linux64.tgz`

Both models and the software manifest will remain pinned to the compatible 11.29.35 / `RD-INFRA-2025.07.03` release pairing. This work includes the official model installers, the public Arm software stack, containerized firmware builds, scripted model launch, and boot-log validation. It does not add custom firmware modifications, OpenBMC, or model configuration changes.

## Layout

```
/home/sjh/arm-fvp/
├── models/
│   ├── rdv3r1/
│   └── rdv3r1-cfg1/
├── stack/
├── logs/
└── scripts/
```

The FVP installers are unpacked into a temporary directory below the workspace and installed into the two `models/` directories. The Arm source stack is a single pinned `repo` checkout. Model-specific build output and logs are kept distinct by platform, preventing cross-platform artifact confusion while avoiding the space cost of two complete source trees.

## Build and Run Flow

1. Confirm archive integrity and inspect the vendor installers for supported non-interactive options.
2. Install each model inside its dedicated `models/` prefix and record its executable path and version.
3. Install or validate host prerequisites: Git, the `repo` client, Docker, and container execution for the current user.
4. Synchronize the Arm `infra-refdesign-manifests` checkout at `RD-INFRA-2025.07.03` with shallow history and its required submodules.
5. Build the Arm `rdinfra-builder` container and use it to build/package the RD-V3-R1 Buildroot artifacts.
6. Launch RD-V3-R1 through Arm's model scripts with the installed model path; preserve console logs and validate the expected firmware-to-Linux boot flow.
7. Build/package and launch the Cfg1 platform using its model and platform configuration; preserve an independent log and validate the same milestone.
8. Provide stable wrappers or documented commands for later launches.

## Validation

Success requires all of the following:

- Both installed model executables report their model/version information.
- The pinned source synchronization completes without uncommitted alterations to Arm source components.
- Both platform builds produce their model-consumable firmware package.
- Each FVP runs to an observable Linux/Buildroot login or shell prompt.
- Saved logs identify startup of the firmware control processors and the non-secure Linux console, with no model-instantiation or missing-image error.

## Constraints and Risks

- The host is Ubuntu 26.04 x86-64. Arm's FVP guide names Ubuntu 22.04 and 24.04; containerizing firmware builds reduces dependency risk, but model execution on 26.04 is best-effort rather than vendor-certified.
- FVP installation and model execution are user-space operations. Installing Docker or missing host packages may require `sudo` and cannot proceed if user authentication is unavailable.
- The shared stack is chosen because current free space is 146 GB, while Arm's full environment documentation recommends significantly more capacity than a duplicated two-checkout workflow can safely consume.
