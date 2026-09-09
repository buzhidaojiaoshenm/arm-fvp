# RD-V3-R1 FVP Runbook

## Supported release

This workspace pairs the Arm FVP 11.29.35 bundles with the pinned
`RD-INFRA-2025.07.03` software release:

- `FVP_RD_V3_R1_11.29_35_Linux64.tgz`
- `FVP_RD_V3_R1_Cfg1_11.29_35_Linux64.tgz`
- `infra-refdesign-manifests` tag `RD-INFRA-2025.07.03`

The firmware build runs in Docker. The current user must be able to run
`docker` without an interactive `sudo` prompt. Arm documents Ubuntu 22.04 and
24.04 for these models; execution on this Ubuntu 26.04 host is best-effort and
has been validated with the workflow below.

## Workflow

Run the commands from the repository root in this order:

```bash
bash scripts/install-fvps.sh
bash scripts/sync-rdinfra-stack.sh
bash scripts/build-rdv3r1.sh
bash scripts/run-rdv3r1.sh
bash scripts/build-rdv3r1-cfg1.sh
bash scripts/run-rdv3r1-cfg1.sh
```

The six wrappers have the following roles:

| Wrapper | Purpose |
| --- | --- |
| `scripts/install-fvps.sh` | Install both supplied FVP bundles below `models/`. |
| `scripts/sync-rdinfra-stack.sh` | Sync the pinned Arm stack and apply the tracked compatibility fixes. |
| `scripts/build-rdv3r1.sh` | Build and package the `rdv3r1` Buildroot stack in Docker. |
| `scripts/run-rdv3r1.sh` | Run the RD-V3-R1 headless boot validation. |
| `scripts/build-rdv3r1-cfg1.sh` | Build and package the `rdv3r1cfg1` Buildroot stack in Docker. |
| `scripts/run-rdv3r1-cfg1.sh` | Run the RD-V3-R1-Cfg1 headless boot validation. |

The run wrappers use Arm's `boot-buildroot.sh` with `-j -t`. They capture UART
output without opening graphical terminals, wait for `buildroot login`, and
terminate the model after the marker is observed. A successful run exits with
status 0 and prints `Buildroot boot test completed`.

For a persistent RD-V3-R1 run that delegates console handling to the upstream
model scripts, use the explicit interactive mode:

```bash
bash scripts/run-rdv3r1.sh --interactive
```

This mode omits `-j -t`, so it does not automatically stop the model after the
Buildroot login marker. RD-V3-R1-Cfg1 currently provides the automated
validation mode only.

## Models and artifacts

The installed executables are:

```text
models/rdv3r1/models/Linux64_GCC-9.3/FVP_RD_V3_R1
models/rdv3r1-cfg1/models/Linux64_GCC-9.3/FVP_RD_V3_R1_Cfg1
```

The principal packaged artifacts are:

```text
stack/output/rdv3r1/grub-buildroot.img
stack/output/rdv3r1/rdv3r1/fip-uefi.bin
stack/output/rdv3r1/rdv3r1/Image
stack/output/rdv3r1cfg1/grub-buildroot.img
stack/output/rdv3r1cfg1/rdv3r1cfg1/fip-uefi.bin
stack/output/rdv3r1cfg1/rdv3r1cfg1/Image
```

## Boot evidence and logs

A complete boot progresses through the RSE, SCP/MCP, TF-A BL31, UEFI, GRUB,
Linux, and Buildroot stages. The acceptance markers on the non-secure AP UART
are:

```text
Linux version ...
Run /init as init process
Welcome to Buildroot
buildroot login:
```

Timestamped UART logs are written below:

```text
stack/model-scripts/rdinfra/platforms/rdv3r1/rdv3r1/
stack/model-scripts/rdinfra/platforms/rdv3r1cfg1/rdv3r1cfg1/
```

The non-secure console filenames contain `uart-0-nsec`. Build command output
can be retained separately under `logs/rdv3r1/` and `logs/rdv3r1-cfg1/`.
Generated models, stack sources, artifacts, archives, and logs are intentionally
not tracked by Git.

## Host memory requirement

These FVPs require much more host memory than their firmware images suggest.
On the validated host with about 14 GiB RAM:

- RD-V3-R1 reached the Buildroot login prompt with about 10.3 GiB peak FVP RSS
  and 16 GiB total swap configured.
- RD-V3-R1-Cfg1 exhausted 16 GiB swap and was killed by the kernel OOM killer.
  At that point the FVP held about 11.3 GiB resident memory and 10.0 GiB swapped
  memory. It completed successfully after total swap was increased to 32 GiB.

For a 16 GiB-class workstation, configure at least 32 GiB total swap before
running Cfg1 and close other memory-heavy applications. Verify capacity with:

```bash
free -h
swapon --show
```

Heavy swapping makes the desktop and even simple status commands temporarily
unresponsive; this is expected during Cfg1 model initialization.

## Verification

Run the tracked checks without rebuilding the generated stack:

```bash
bash tests/test_install_fvps.sh
bash tests/test_stack_manifest.sh
bash tests/test_rdv3r1_artifacts.sh
bash tests/test_rdv3r1_cfg1_artifacts.sh
bash tests/test_fvp_runbook.sh
```
