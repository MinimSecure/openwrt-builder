# openwrt-builder

Build preconfigured OpenWrt images and binary packages inside a Docker
container.

[![minimsecure/circleci-openwrt-builder on Docker Hub](https://img.shields.io/docker/build/minimsecure/circleci-openwrt-builder.svg?style=flat-square)](https://hub.docker.com/r/minimsecure/circleci-openwrt-builder)

## Overview

Currently supported OpenWrt targets:

- TP-LINK Archer C7 v2
- TP-LINK Archer C7 v4
- Linksys WRT1900ACS
- GL.iNet AR-300M
- GL.iNet GL-B1300

Architectures:

- ar71xx (mips_24kc)
- ipq40xx (armv7l)
- mvebu-cortexa9 (armv7l)
