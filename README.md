# openwrt-builder

Build OpenWrt images and packages using a preconfigured buildroot inside 
Docker containers.

[![CircleCI Build Status](https://img.shields.io/circleci/project/github/MinimSecure/openwrt-builder.svg?style=flat-square)][1]
[![minimsecure/openwrt-builder on Docker Hub](https://img.shields.io/badge/docker%20hub-repo-blue.svg?style=flat-square)][2]

## Overview

This repository is used to build an OpenWrt buildroot in stages, first building
the reusable toolchain for a specific hardware platform, then building the
final OpenWrt firmware images and [Unum][3] installation packages for a 
specific device.

For example, use the `minimsecure/openwrt-builder:ar71xx` Docker image
to build an OpenWrt firmware image for GL.iNet AR300M:

```bash
# Build 
docker run --name=openwrt-ar71xx -it \
    minimsecure/openwrt-builder:ar71xx \
    make gl_ar300m
# Copy the newly built OpenWrt firmware images and Unum .ipk onto the host
docker cp openwrt-ar71xx:/builder/build/out/* . 
```


## Supported Platforms

### `ar71xx`

* TP-LINK Archer C7 v2
* TP-LINK Archer C7 v4
* GL.iNet AR-300M
```bash
docker run minimsecure/openwrt-builder:ar71xx
```

### `ipq40xx`

* GL.iNet GL-B1300
```bash
docker run minimsecure/openwrt-builder:ipq40xx
```

### `mvebu-cortexa9`

* Linksys WRT1900ACS
```bash
docker run minimsecure/openwrt-builder:mvebu-cortexa9
```


## Adding New Platforms

Three files must exist for each device supported, all inside the `platforms/`
directory.

In the list below, replace `<chipset>` with the chipset name and
`<device>` with a short name (no spaces) representing your device.
For example, `ar71xx` and `archer_c7_v4` as chipset and device, respectively.

1. `<chipset>.config.seed` contains the default build configuration for a 
   target chipset without any specific devices
   enabled.
2. `<device>.baseconfig` must be a symlink to the appropriate 
   `<chipset>.config.seed` file.
3. `<device>.diffconfig` should contain any changes needed for a specific 
   device. Usually this requires only selecting the device and setting the 
   product name.


[1]: https://circleci.com/gh/MinimSecure/unum-sdk
[2]: https://hub.docker.com/r/minimsecure/openwrt-builder
[3]: https://github.com/MinimSecure/unum-sdk
