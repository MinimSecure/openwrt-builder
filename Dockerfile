FROM debian:stretch-slim

RUN apt-get update && \
    apt-get install -y subversion g++ zlib1g-dev build-essential git python rsync man-db && \
    apt-get install -y libncurses5-dev gawk gettext unzip file libssl-dev wget zip time

WORKDIR /workdir

RUN useradd -m openwrt

RUN chown -R openwrt: /workdir

USER openwrt

RUN git clone --depth=1 --branch=v18.06.1 https://github.com/openwrt/openwrt openwrt

RUN wget https://downloads.openwrt.org/releases/18.06.1/targets/ar71xx/generic/openwrt-sdk-18.06.1-ar71xx-generic_gcc-7.3.0_musl.Linux-x86_64.tar.xz
RUN tar -C /workdir/openwrt -xf openwrt-sdk-18.06.1-ar71xx-generic_gcc-7.3.0_musl.Linux-x86_64.tar.xz

RUN wget https://downloads.openwrt.org/releases/18.06.1/targets/ipq40xx/generic/openwrt-sdk-18.06.1-ipq40xx_gcc-7.3.0_musl_eabi.Linux-x86_64.tar.xz
RUN tar -C /workdir/openwrt -xf openwrt-sdk-18.06.1-ipq40xx_gcc-7.3.0_musl_eabi.Linux-x86_64.tar.xz

RUN wget https://downloads.openwrt.org/releases/18.06.1/targets/mvebu/cortexa9/openwrt-sdk-18.06.1-mvebu-cortexa9_gcc-7.3.0_musl_eabi.Linux-x86_64.tar.xz
RUN tar -C /workdir/openwrt -xf openwrt-sdk-18.06.1-mvebu-cortexa9_gcc-7.3.0_musl_eabi.Linux-x86_64.tar.xz


RUN git clone --depth=1 https://github.com/MinimSecure/openwrt-builder builder

RUN ln -sf /workdir/openwrt /workdir/builder/openwrt

RUN cd openwrt && \
    cp -f feeds.conf.default feeds.conf && \
    echo "# Minim open source feed containing Unum agent" >> feeds.conf && \
    echo "src-git minim https://github.com/MinimSecure/minim-openwrt-feed" >> feeds.conf && \
    ./scripts/feeds update -a && \
    ./scripts/feeds install -a

RUN make -C /workdir/builder V=s -j1
