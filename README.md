
# arm-fvp

Reproducible wrappers for Arm RD-V3-R1 and RD-V3-R1-Cfg1 FVP 11.29.35 with
the pinned `RD-INFRA-2025.07.03` software stack.

## Important licensing boundary

This repository does not redistribute Arm's proprietary FVP archives or
installed model binaries. Obtain the archives from Arm, review and accept the
contained EULA, then copy these files to the repository root:

- `FVP_RD_V3_R1_11.29_35_Linux64.tgz`
- `FVP_RD_V3_R1_Cfg1_11.29_35_Linux64.tgz`

The archives, installed models, build products, and logs are intentionally
ignored by Git. The RD-INFRA source repositories are recorded as pinned Git
submodules; their source objects are fetched from the respective upstreams.

## Host prerequisites

- x86-64 Linux; Ubuntu 22.04 or 24.04 is the documented model host
- Git, curl, tar, and Docker
- permission to run Docker without an interactive `sudo` prompt
- network access to Arm GitLab and the upstream component repositories
- about 16 GiB RAM; use at least 32 GiB total swap for RD-V3-R1-Cfg1 on a
  16 GiB-class workstation

## Clone and prepare

```bash
git clone --recurse-submodules --shallow-submodules \
  git@github.com:buzhidaojiaoshenm/arm-fvp.git
cd arm-fvp
```

After placing the two FVP archives above in the repository root, and only
after reviewing and accepting their contained Arm EULA, install the models and
sync the pinned source stack:

```bash
bash scripts/install-fvps.sh
bash scripts/sync-rdinfra-stack.sh
```

## Build and validate RD-V3-R1

```bash
bash scripts/build-rdv3r1.sh
bash scripts/run-rdv3r1.sh
```

The default run is headless. It waits for `buildroot login`, stops the model,
and returns success. To leave the RD-V3-R1 model running through the upstream
console flow, use:

```bash
bash scripts/run-rdv3r1.sh --interactive
```

## Build and validate RD-V3-R1-Cfg1

```bash
bash scripts/build-rdv3r1-cfg1.sh
bash scripts/run-rdv3r1-cfg1.sh
```

Cfg1 requires substantially more host memory and swap than RD-V3-R1.

## Documentation and checks

- [Detailed runbook](docs/rdv3r1-fvp-runbook.md)
- [Host preflight](docs/rdv3r1-fvp-preflight.md)

Run the tracked checks without rebuilding:

```bash
for test in tests/test_*.sh; do bash "$test"; done
```

## Detailed build and boot flow

# 项目总体结构

  这个项目实际上包含两类东西：

  1. FVP 硬件模型：Arm 已经编译好的闭源二进制，只负责安装和运行，不在本项目中编译。
  2. RD-INFRA 软件栈：TF-M/RSE、SCP/MCP/LCP、TF-A、RMM、UEFI、Linux、Buildroot、GRUB 等源码，需要在 Docker 中编译
     和打包。

  完整链路可以概括为：

  ```text
  FVP 安装包                     Arm RD-INFRA 源码
      │                                │
      │ 安装预编译模型                 │ Docker 中编译
      ▼                                ▼
  FVP_RD_V3_R1              各组件原始二进制
                                   │
                                   │ 签名、汇总、打包
                                   ▼
                     ┌──────────────────────────┐
                     │ TF-M ROM/Flash           │
                     │ FIP：TF-A + RMM + UEFI   │
                     │ GPT：GRUB + Linux + rootfs│
                     └──────────────────────────┘
                                   │
                                   │ 作为参数加载进 FVP
                                   ▼
   RSE → SCP/MCP/LCP → TF-A → RMM → UEFI → GRUB → Linux → Buildroot
  ```

  ———

  # 一、准备阶段

  ## 1. 安装 FVP 模型

  执行：

  bash scripts/install-fvps.sh

  脚本从项目根目录的两个压缩包中提取 Arm 安装器：

  FVP_RD_V3_R1_11.29_35_Linux64.tgz
  FVP_RD_V3_R1_Cfg1_11.29_35_Linux64.tgz

  然后以非交互方式安装到：

  models/rdv3r1/
  models/rdv3r1-cfg1/

  入口见 scripts/install-fvps.sh:9。

  最终可执行文件是：

  models/rdv3r1/models/Linux64_GCC-9.3/FVP_RD_V3_R1
  models/rdv3r1-cfg1/models/Linux64_GCC-9.3/FVP_RD_V3_R1_Cfg1

  这里没有编译 FVP，它们是 Arm 已经提供好的模型程序。

  ## 2. 同步 RD-INFRA 源码

  执行：

  bash scripts/sync-rdinfra-stack.sh

  父仓库通过 `.gitmodules` 记录 19 个上游 Git submodule，并将每个仓库固定到
  `RD-INFRA-2025.07.03` 对应的精确提交。脚本先执行浅递归初始化；若上游不支持
  shallow fetch，则自动退回普通递归初始化。随后装配 EDK2 Platforms 兼容路径并
  应用本仓库维护的补丁。

  入口见 `scripts/sync-rdinfra-stack.sh`。

  同步后，stack/ 下主要包含：

| 目录 | 内容 |
| --- | --- |
| `tf-m/` | RSE/TF-M 安全固件 |
| `scp/` | SCP、MCP、LCP 固件 |
| `tf-a/` | AP 侧 BL1、BL2、BL31 |
| `rmm/` | Realm Management Monitor |
| `uefi/edk2/` | UEFI 固件 |
| `uefi/edk2-platforms/` | EDK2 平台代码；同步脚本装配兼容路径 |
| `linux/` | Linux 内核 |
| `buildroot/` | 根文件系统 |
| `grub/` | GRUB EFI 引导程序 |
| `kvmtool/` | Realm/KVM 测试工具 |
| `build-scripts/` | 组件编译和打包框架 |
| `model-scripts/` | FVP 启动脚本 |
| `container-scripts/` | Docker 构建环境 |

  同步完成后还会应用四个本地兼容补丁：

  - Docker 构建时代理和下载重试支持。
  - common_run_model.sh 的公共辅助脚本路径修复。
  - Buildroot 的 util-linux binaries 和 numactl 包配置。
  - Realm 测试的 PMU counter 数量适配。

  见 scripts/apply-rdinfra-fixes.sh:19。

  ———

  # 二、源码编译流程

  ## 1. 顶层编译入口

  RD-V3-R1：

  bash scripts/build-rdv3r1.sh

  RD-V3-R1-Cfg1：

  bash scripts/build-rdv3r1-cfg1.sh

  两个脚本的结构相同，区别只是传给底层的 platform 名称：

  rdv3r1
  rdv3r1cfg1

  以 RD-V3-R1 为例，脚本首先执行：

  cd stack/container-scripts
  ./container.sh build

  然后启动：

  rdinfra-builder

  镜像对应的临时容器，并在容器中执行：

  ./build-scripts/rdinfra/build-test-buildroot.sh -p rdv3r1 build
  ./build-scripts/rdinfra/build-test-buildroot.sh -p rdv3r1 package

  见 scripts/build-rdv3r1.sh:20。

  注意：这里是先执行完整的 build，成功后才执行 package，没有隐式执行 clean。

  ## 2. Docker 环境

  Docker 镜像由本地 Dockerfile 构建，基础镜像是：

  ubuntu:jammy-20240911.1

  并安装：

  - GCC 13.2.rel1 arm-none-eabi
  - GCC 13.2.rel1 aarch64-none-elf
  - GCC 13.2.rel1 aarch64-none-linux-gnu
  - Clang/LLVM 15.0.6
  - CMake、Ninja、DTC、mtools、gdisk、OpenSSL 等工具

  见 stack/container-scripts/container-files/rd-infra-amd64:29。

  宿主机的整个 stack/ 目录被挂载进容器：

  宿主机 /home/sjh/arm-fvp/stack
                    ⇅
  容器   /home/sjh/arm-fvp/stack

  因此源码、编译中间文件和最终产物都仍保存在宿主机。容器退出不会删除它们。

  ## 3. 构建框架如何选择平台

  build-test-buildroot.sh 将命令转换为：

  build-all.sh -p rdv3r1 -f buildroot build

  或者：

  build-all.sh -p rdv3r1 -f buildroot package

  见 stack/build-scripts/sgi/build-test-buildroot.sh:93。

  然后 build-all.sh 依次读取：

  build-scripts/configs/rdv3r1/rdv3r1
  build-scripts/filesystems/buildroot

  平台配置决定：

  - 编译哪些组件。
  - 使用什么工具链。
  - 平台 variant。
  - 芯片数量。
  - TF-A、TF-M、SCP、UEFI 的构建参数。
  - 最终产物如何汇总。

  组件脚本由 build-all.sh 顺序执行，每个组件最终进入自己的 do_build() 或 do_package()。stack/build-scripts/build-
  all.sh:135

  ## 4. 两个平台的主要差异

| 参数 | RD-V3-R1 | RD-V3-R1-Cfg1 |
| --- | --- | --- |
| `CHIP_COUNT` | 2 | 4 |
| `TF_M_PLATFORM_VARIANT` | 0 | 1 |
| `SCP_PLATFORM_VARIANT` | 0 | 1 |
| `TF_A_PLATFORM_VARIANT` | 0 | 1 |
| UEFI 平台 | `RdV3R1` | `RdV3R1Cfg1` |
| FVP 拓扑 | 1 socket × 2 CSS | 2 socket × 2 CSS |
| 每芯片 provisioning 镜像 | 0、1 | 0、1、2、3 |

  参见 stack/build-scripts/configs/rdv3r1/rdv3r1:33和 stack/build-scripts/configs/rdv3r1cfg1/rdv3r1cfg1:33。

  ## 5. 实际组件编译顺序

  平台配置最终给出的顺序是：

  ```text
  RMM
    ↓
  kvmtool / kvm-unit-tests
    ↓
  TF-M / RSE
    ↓
  SCP / MCP / LCP
    ↓
  Hafnium（当前配置关闭）
    ↓
  UEFI
    ↓
  TF-A
    ↓
  Linux
    ↓
  BusyBox（buildroot 模式下关闭）
    ↓
  Buildroot
    ↓
  GRUB
    ↓
  Target Binaries 汇总
  ```

  配置入口见 stack/build-scripts/configs/rdv3r1/rdv3r1:194。

  ### RMM

  通过 CMake 编译 Realm Management Monitor：

  cmake -DRMM_CONFIG=rdv3r1_defcfg ...
  cmake --build build

  输出：

  rmm.img

  见 stack/build-scripts/build-rmm.sh:45。

  ### kvmtool 和 kvm-unit-tests

  使用 AArch64 Linux 交叉编译器构建：

  lkvm-static
  kvm-unit-tests

  这些不是宿主机工具，而是后续放入 guest 磁盘中，用于 Realm/KVM 验证。stack/build-scripts/build-kvmtool.sh:66

  ### TF-M / RSE

  使用 arm-none-eabi 编译 RSE 安全固件，主要生成：

  rom.bin
  flash.bin
  vm0_<chip>.bin
  vm1_<chip>.bin
  tf-bl1.bin

  其中：

  - rom.bin：RSE ROM 初始镜像。
  - flash.bin：RSE BL2 和 TF-M Secure 镜像。
  - vm0/vm1：每个芯片的 CM/DM provisioning 数据。
  - tf-bl1.bin：AP 侧 TF-A BL1，后续被加入 RSE flash。

  TF-M 构建和基础 flash 拼接见 stack/build-scripts/build-tf-m.sh:112。

  ### SCP / MCP / LCP

  对三个固件分别执行 CMake/Ninja：

  scp_ramfw
  mcp_ramfw
  lcp_ramfw

  工具链是 arm-none-eabi，Variant 0 和 Variant 1 使用不同平台配置。stack/build-scripts/build-scp.sh:98

  这些固件负责：

  - SCP：芯片电源、时钟、系统控制。
  - MCP：多芯片/系统管理。
  - LCP：链路和互联相关控制。

  ### UEFI

  EDK2 构建分为：

  1. 编译 ACPICA iasl。
  2. 编译 EDK2 BaseTools。
  3. 编译对应平台 DSC。

  RD-V3-R1 使用：

  Platform/ARM/SgiPkg/RdV3R1/RdV3R1.dsc

  Cfg1 使用：

  Platform/ARM/SgiPkg/RdV3R1Cfg1/RdV3R1Cfg1.dsc

  最终输出统一复制为：

  uefi.bin

  见 stack/build-scripts/build-uefi.sh:50。

  ### TF-A

  TF-A 编译产生：

  BL1
  BL2
  BL31
  平台配置 DTB
  cert_create
  fiptool

  当前配置启用了：

  - Trusted Board Boot。
  - RME。
  - RMM。
  - CCA 证书链。
  - Measured Boot。
  - Debug 构建。

  见 stack/build-scripts/build-tf-a.sh:48。

  ### Linux

  使用：

  ARCH=arm64
  CROSS_COMPILE=aarch64-none-linux-gnu-

  主要执行：

  make defconfig
  make Image dtbs
  make headers_install
  make tools/iommu

  生成：

  Image
  DTB
  smmute

  见 stack/build-scripts/build-linux.sh:58。

  ### Buildroot

  Buildroot 根据平台 defconfig 构建最小用户空间，并生成：

  rootfs.cpio

  随后复制为：

  ramdisk-buildroot.img

  见 stack/build-scripts/build-buildroot.sh:45。

  ### GRUB

  GRUB 被交叉编译成 ARM64 EFI 程序：

  grubaa64.efi

  其中嵌入平台 GRUB 配置，支持 GPT、FAT、EXT 文件系统和 Linux EFI 启动。stack/build-scripts/build-grub.sh:44

  ———
  # 三、打包流程

  打包不是简单压缩，而是分成三个层次。

  ## 1. 汇总组件产物

  每个组件的 do_package() 将原始产物复制到：

  stack/output/<platform>/components/

  例如：

  components/rdv3r1/
  components/css-common/uefi.bin
  components/linux/Image
  components/kvmtool/lkvm
  components/kvm-ut/

  这里属于中间汇总区。

  ## 2. 生成 TF-M 启动镜像

  build-target-bins.sh 首先使用 MCUboot 对以下镜像签名：

  scp_ramfw.bin
  mcp_ramfw.bin
  lcp_ramfw.bin
  tf-bl1.bin

  然后将它们与 TF-M 的基础 flash.bin 按固定偏移拼接：

  TF-M BL2 / Secure image
  signed SCP RAM firmware
  signed MCP RAM firmware
  signed LCP RAM firmware
  signed AP TF-A BL1

  生成：

  tf_m_flash.bin

  同时导出：

  tf_m_rom.bin
  tf_m_vm0_0.bin
  tf_m_vm1_0.bin
  ...

  签名和拼接逻辑见 stack/build-scripts/build-target-bins.sh:173。

  这意味着 AP 的 TF-A BL1 不在 FIP 中，而是由 RSE 启动链从 TF-M flash 中装载。

  ## 3. 生成 AP FIP

  cert_create 先生成 Trusted Board Boot/CCA 证书，然后 fiptool 创建：

  fip-uefi.bin

  当前实际 FIP 中包含：

| FIP 条目 | 来源 |
| --- | --- |
| BL2 | TF-A |
| BL31 | TF-A |
| BL33 | UEFI |
| RMM | RMM |
| `FW_CONFIG` | TF-A 平台配置 |
| `HW_CONFIG` | TF-A 平台配置 |
| `TB_FW_CONFIG` | TF-A 平台配置 |
| `NT_FW_CONFIG` | TF-A 平台配置 |
| 证书 | TBBR/CCA 证书链 |

  UEFI 作为 Non-Trusted Firmware BL33 写入 FIP。stack/build-scripts/build-target-bins.sh:474

  ## 4. 生成 GRUB 磁盘镜像

  组件打包完成后，外层 build-test-buildroot.sh 创建：

  grub-buildroot.img

  当前镜像是约 222 MiB 的 GPT 磁盘：

  ```text
  GPT
  ├── 分区 1：20 MiB FAT
  │   ├── /EFI/BOOT/bootaa64.efi
  │   └── /grub/grub.cfg
  └── 分区 2：200 MiB EXT3
      ├── /Image
      ├── /ramdisk-buildroot.img
      ├── /smmute
      ├── /lkvm
      └── /kvm-ut/
  ```

  创建过程见 stack/build-scripts/sgi/build-test-buildroot.sh:173。

  GRUB 菜单最终执行：

  linux /Image ...
  initrd /ramdisk-buildroot.img

  见 stack/build-scripts/configs/rdv3r1/grub_config/buildroot.cfg:6。

  ## 5. 最终运行目录

  RD-V3-R1：

  ```text
  stack/output/rdv3r1/
  ├── grub-buildroot.img
  ├── ramdisk-buildroot.img
  ├── components/
  └── rdv3r1/
      ├── fip-uefi.bin
      ├── tf_m_rom.bin
      ├── tf_m_flash.bin
      ├── tf_m_vm0_0.bin
      ├── tf_m_vm1_0.bin
      ├── ...
      ├── Image
      ├── rmm.img
      └── uefi.bin
  ```

  Cfg1 对应：

  stack/output/rdv3r1cfg1/rdv3r1cfg1/

  其中很多文件是指向 components/ 的相对符号链接，真正独立生成的重要镜像是：

  fip-uefi.bin
  tf_m_flash.bin
  grub-buildroot.img

  ———

  # 四、FVP 运行流程

  ## 1. 顶层运行入口

  RD-V3-R1：

  bash scripts/run-rdv3r1.sh

  Cfg1：

  bash scripts/run-rdv3r1-cfg1.sh

  脚本先寻找已安装的 FVP 可执行文件，然后执行：

  MODEL=<FVP路径> ./boot-buildroot.sh -p rdv3r1 -j -t

  见 scripts/run-rdv3r1.sh:5。

  参数含义：

  - -p rdv3r1：选择平台。
  - -j：headless，不打开图形终端。
  - -t：检测到 Buildroot 启动成功后结束 FVP。

  FVP 运行发生在宿主机，不在 Docker 中。

  ## 2. 给 FVP 装载哪些镜像

  运行脚本建立三条装载路径：

| 镜像 | FVP 装载位置 | 用途 |
| --- | --- | --- |
| `tf_m_rom.bin` | 每个 RSE 的 ROM | RSE 第一级启动 |
| `tf_m_flash.bin` | 每个 RSE 的 Flash 地址 | TF-M、SCP/MCP/LCP、AP BL1 |
| `tf_m_vm0/1_<chip>.bin` | 每个 RSE provisioning 地址 | 芯片身份和安全配置 |
| `fip-uefi.bin` | AP flashloader0 | BL2、BL31、RMM、UEFI |
| `grub-buildroot.img` | VirtIO block device | GRUB、Linux、Buildroot rootfs |
| `nor1_flash.img`、`nor2_flash.img` | 可写 NOR | UEFI 变量和持久化数据 |

  RD-V3-R1 的具体装载参数见 stack/model-scripts/rdinfra/platforms/rdv3r1/run_model.sh:238。

  Cfg1 会分别给四个 RSE 装载 vm0/vm1_0..3：stack/model-scripts/rdinfra/platforms/rdv3r1cfg1/run_model.sh:299。

  grub-buildroot.img 由 boot-buildroot.sh 通过 -v 传给平台脚本，最终挂载为 VirtIO 磁盘。stack/model-scripts/sgi/
  boot-buildroot.sh:106

  ## 3. 上电后的固件时序

  完整启动过程是：

  ```text
  FVP 启动
    │
    ├─ RSE ROM：tf_m_rom.bin
    │      │
    │      └─ 验证并启动 RSE BL2 / TF-M
    │
    ├─ RSE BL2 从 tf_m_flash.bin 取出：
    │      ├─ SCP RAM firmware
    │      ├─ MCP RAM firmware
    │      ├─ LCP RAM firmware
    │      └─ AP TF-A BL1
    │
    ├─ SCP/MCP/LCP 初始化
    │      ├─ 电源和时钟
    │      ├─ 多芯片互联
    │      ├─ 系统控制
    │      └─ 释放 AP
    │
    ├─ AP TF-A BL1
    │      ├─ 建立可信启动环境
    │      ├─ 验证证书
    │      └─ 从 fip-uefi.bin 加载 BL2
    │
    ├─ TF-A BL2
    │      ├─ 加载配置 DTB
    │      ├─ 加载 BL31
    │      ├─ 加载 RMM
    │      └─ 加载 UEFI（BL33）
    │
    ├─ TF-A BL31
    │      ├─ 驻留 EL3
    │      ├─ 初始化 RME/RMM 接口
    │      └─ 跳转 UEFI
    │
    ├─ UEFI
    │      ├─ 初始化设备和 ACPI
    │      └─ 从 VirtIO GPT 磁盘启动 bootaa64.efi
    │
    ├─ GRUB
    │      ├─ 搜索 EXT3 分区 UUID
    │      ├─ 加载 /Image
    │      └─ 加载 /ramdisk-buildroot.img
    │
    ├─ Linux
    │      ├─ EFI stub
    │      ├─ 解压和初始化内核
    │      └─ 执行 initramfs 中的 /init
    │
    └─ Buildroot
           └─ 输出 buildroot login:
  ```

  当前保存的成功日志也体现了：

  UEFI firmware
  Welcome to GRUB
  EFI stub: Booting Linux Kernel
  Linux version 6.10...
  Run /init as init process
  Welcome to Buildroot
  buildroot login:

  见 stack/model-scripts/rdinfra/platforms/rdv3r1/rdv3r1/refinfra-3140406-uart-0-nsec_2026-08-
  24_17.07.52.txt:213。

  ## 4. 日志与成功判定

  FVP 会分别输出：

  RSE UART
  SCP UART
  MCP UART
  LCP UART
  AP Secure UART
  AP Non-secure UART
  RMM UART

  启动包装脚本重点监控 AP Non-secure UART，并等待：

  buildroot login

  最长等待 7200 秒。检测到后：

  1. 返回启动成功。
  2. 因为指定了 -t，杀掉 FVP 及其子进程。
  3. 输出：

  [SUCCESS]: Buildroot boot test completed!

  判定逻辑见 stack/model-scripts/sgi/boot-buildroot.sh:119。

  因此，这套项目的核心交付不是单个程序，而是三个相互配合的启动载体：

  tf_m_flash.bin     控制面和安全启动链
  fip-uefi.bin       AP 可信固件和 UEFI
  grub-buildroot.img 操作系统启动磁盘

  只有三者与对应的 FVP 模型、平台 Variant 和芯片数量一致，系统才能完整启动到 Buildroot。
