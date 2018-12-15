# openwrt-builder

Build preconfigured OpenWrt images and binary packages inside a Docker
container.

[![CircleCI Build Status](https://img.shields.io/circleci/project/github/MinimSecure/openwrt-builder.svg?style=flat-square)][1]
[![minimsecure/circleci-openwrt-builder on Docker Hub](https://img.shields.io/badge/docker%20hub-repo-blue.svg?style=flat-square)][2]

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

[1]: https://circleci.com/gh/MinimSecure/unum-sdk
[2]: https://hub.docker.com/r/minimsecure/circleci-openwrt-builder
