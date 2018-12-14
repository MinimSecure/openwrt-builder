FROM debian:stretch-slim

RUN echo 'path-exclude /usr/share/doc/*\
path-include /usr/share/doc/*/copyright\
path-exclude /usr/share/man/*\
path-exclude /usr/share/groff/*\
path-exclude /usr/share/info/*\
path-exclude /usr/share/lintian/*\
path-exclude /usr/share/linda/*' > /etc/dpkg/dpkg.cfg.d/01_nodoc

RUN apt-get update && \
    apt-get install -y subversion g++ zlib1g-dev build-essential git python rsync man-db && \
    apt-get install -y libncurses5-dev gawk gettext unzip file libssl-dev wget zip time && \
    apt-get clean

WORKDIR /workdir

COPY . builder

RUN useradd -m openwrt

RUN chown -R openwrt: .

USER openwrt

RUN make -C /workdir/builder gl_b1300.sdk

RUN make -C /workdir/builder gl_b1300
