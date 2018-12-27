# openwrt-builder

Devops images for building OpenWrt specific images and packages using a preconfigured buildroot.

[![CircleCI Build Status](https://img.shields.io/circleci/project/github/MinimSecure/openwrt-builder.svg?style=flat-square)][1]
[![minimsecure/circleci-openwrt-builder on Docker Hub](https://img.shields.io/badge/docker%20hub-repo-blue.svg?style=flat-square)][2]

## Overview

Currently supported OpenWrt targets:

* `ar71xx`
  * TP-LINK Archer C7 v2
  * TP-LINK Archer C7 v4
  * GL.iNet AR-300M
  ```bash
  docker run minimsecure/circleci-openwrt-builder:ar71xx
  ```
* `ipq40xx`
  * GL.iNet GL-B1300
  ```bash
  docker run minimsecure/circleci-openwrt-builder:ipq40xx
  ```
* `mvebu-cortexa9`
  * Linksys WRT1900ACS
  ```bash
  docker run minimsecure/circleci-openwrt-builder:mvebu-cortexa9
  ```

[1]: https://circleci.com/gh/MinimSecure/unum-sdk
[2]: https://hub.docker.com/r/minimsecure/circleci-openwrt-builder
