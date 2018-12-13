FROM debian:stretch-slim

RUN apt-get update && \
    apt-get install -y subversion g++ zlib1g-dev build-essential git python rsync man-db && \
    apt-get install -y libncurses5-dev gawk gettext unzip file libssl-dev wget zip time

WORKDIR /workdir

RUN useradd -m openwrt

RUN chown -R openwrt: /workdir

USER openwrt

RUN git clone --depth=1 --branch=v18.06.1 https://github.com/openwrt/openwrt openwrt

RUN git clone --depth=1 https://github.com/MinimSecure/openwrt-builder builder

RUN ln -sf /workdir/openwrt /workdir/builder/openwrt

RUN cd openwrt && \
    cp -f feeds.conf.default feeds.conf && \
    echo "# Minim open source feed containing Unum agent" >> feeds.conf && \
    echo "src-git minim https://github.com/MinimSecure/minim-openwrt-feed" >> feeds.conf && \
    ./scripts/feeds update -a && \
    ./scripts/feeds install -a

RUN make -C /workdir/builder V=s -j1
