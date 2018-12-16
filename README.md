# openwrt-builder

Devops images for building OpenWrt specific images and packages using a preconfigured buildroot.

[![CircleCI Build Status](https://img.shields.io/circleci/project/github/MinimSecure/openwrt-builder.svg?style=flat-square)][1]
[![minimsecure/circleci-openwrt-builder on Docker Hub](https://img.shields.io/badge/docker%20hub-repo-blue.svg?style=flat-square)][2]

## Overview

Currently supported OpenWrt targets:

* TP-LINK Archer C7 v2 (tag: `archer_c7_v2`)
  ```bash
  docker run minimsecure/circleci-openwrt-builder:archer_c7_v2
  ```
* TP-LINK Archer C7 v4 (tag: `archer_c7_v4`)
  ```bash
  docker run minimsecure/circleci-openwrt-builder:archer_c7_v4
  ```
* GL.iNet AR-300M (tag: `gl_ar300m`)
  ```bash
  docker run minimsecure/circleci-openwrt-builder:gl_ar300m
  ```
* GL.iNet GL-B1300 (tag: `gl_b1300`)
  ```bash
  docker run minimsecure/circleci-openwrt-builder:gl_b1300
  ```
* Linksys WRT1900ACS (tag: `linksys-wrt1900acs`)
  ```bash
  docker run minimsecure/circleci-openwrt-builder:linksys-wrt1900acs
  ```

[1]: https://circleci.com/gh/MinimSecure/unum-sdk
[2]: https://hub.docker.com/r/minimsecure/circleci-openwrt-builder
