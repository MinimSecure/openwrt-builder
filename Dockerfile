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

# The `platform` build-arg is required when building an image using this
# Dockerfile. It must be one of the supported devices or platforms, as
# accepted by the Makefile in the working directory of the container.
ARG platform
# Set an environment variable so that the platform name can be known after
# the image is built.
ENV BUILD_PLATFORM=${platform}

WORKDIR /builder
COPY . .
RUN chown -R openwrt: .
USER openwrt

# First stage is to build the appropriate toolchain for the given platform.
RUN make ${BUILD_PLATFORM}.toolchain

# Once the image is built, running it in a docker image will build the
# appropriate firmwares and .ipk packages.
CMD make ${BUILD_PLATFORM}
