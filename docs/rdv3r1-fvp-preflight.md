# RD-V3-R1 FVP Preflight

Date: 2026-08-24 09:56:30 CST

## Release pairing

- FVP: 11.29.35
- RD infrastructure: RD-INFRA-2025.07.03

## Host

```text
$ uname -m
x86_64

$ . /etc/os-release && printf '%s\n' "$PRETTY_NAME"
Ubuntu 26.04 LTS

$ df -h .
Filesystem      Size  Used Avail Use% Mounted on
/dev/nvme0n1p6  251G   93G  146G  39% /home/sjh/arm-fvp
```

## Archive SHA-256

```text
f1c77d0c50dea01a5dd4ea6fbe548919abc0d63f281f8378f6d9fa83932e36cc  FVP_RD_V3_R1_11.29_35_Linux64.tgz
2356488588a085ee45f5decc5f5bb929dd7086f045f438d4b2c5b3594e172ccf  FVP_RD_V3_R1_Cfg1_11.29_35_Linux64.tgz
```

## Docker

Docker client version: 29.7.2

The daemon was not accessible. The preflight command produced:

```text
$ docker version --format '{{.Client.Version}} {{.Server.Version}}'
29.7.2
permission denied while trying to connect to the docker API at unix:///var/run/docker.sock
```

Server version: unavailable because the current user cannot access the Docker daemon.
