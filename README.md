# docker-coreelec
Docker 20.10 for CoreELEC distro

CoreELEC is a Linux system (JeOS - Just enough Operational System) that runs on devices with Amlogic processors. It has the minimum required to run the Kodi system and uses the original Amlogic Kernel for Android (4.9.113) having support for almost all devices embedded (Bluetooth, WiFi, Ethernet, Audio and Video Output, Hardware Video Decoding) using the original Android structure while other Linux distributions often do not support all installed devices.

Usually new software is installed through add-on using the GUI interface (Kodi), where the software is usually aimed for multimedia activities. One exception is the system-oriented software Docker, however it is limited to version 19.

Generally boxes sold with the Amlogic processors line have reasonably high memory for this type of system (4/8 GB) and multi-core processor with a very attractive price. The possibility of using a docker, especially the latest versions with security fixes, can make this type of equipment very efficient for a lot of domestic applications, such as servers for IoT.

This project provides structure to install the Docker version 20.10, latest (fetched directly from Github), on these devices.

## Download releases

[Download releases](https://github.com/fabriciotamusiunas/docker-coreelec/releases)

## Compilation instructions (Linux X86_64/arm64 and macOS)
**Note: If you're compiling it on a platform with a different target architecture, you have to use cross-compiling (buildx).**

### First step: know the device architecture with CoreELEC
- Enable ssh via Kodi / CoreELEC interface on the device
- Access the device via SSH
- Look for the architecture with the uname command:

```bash
# uname -m
```

#### Output table

Output contains |Architecture is
------|------------
aarch64|arm64
armhf or arm7   |arm7
arm6   |arm6

### Second step: compile it on a platform with docker installed and running

To compile for the same platform

```bash
./compile-docker.bash buid
```

To compile on different platform (<arch> is the architecture: arm64, arm7 or arm6)

```bash
./compile-docker.bash buidx -a <arch>
# example: ./compile-docker.bash buidx -a arm64
```

**Depending on your system performance the compilation can take up to 30 minutes.**

When finished a file (.tar.gz) starting with **docker_v20.10** identified by architecture and date will be available locally. Use it to install Docker on CoreELEC.

## Installing or Updating Docker on CoreELEC 

**Important: docker-coreelec (this project) is NOT compatilble with Kodi add-on Docker. If you're using Kodi add-on Docker please remove-it before installing docker-coreelec**

To install it you have to use the download package from [releases](https://github.com/fabriciotamusiunas/docker-coreelec/releases).

Considering you are using the package name "docker\_v20.10.6.m_coreelec\_arm64\_20210422000000.tar.gz":

- Send the package "docker\_v20.10.6.m_coreelec\_arm64\_20210422000000.tar.gz" to device.
- Access the device via SSH and type:

```bash
cd /
# considering that your package is on /storage
tar zxvf /storage/docker_v20.10.6.m_coreelec_arm64.tar.gz
systemctl daemon-reload
systemctl restart service.system.docker
# if you wanna have docker commands on PATH (recommended)
echo "export PATH=/storage/.docker/bin:$PATH" >> /storage/.profile
```

All docker executable files are at "/storage/.docker/bin". 

The daemon.config file is at "/storage/.config/docker/daemon.json"

The data-root directory is "/storage/.docker/data-root"
