# Copyright 2018 Minim Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Figure the top level directory
TOP := $(patsubst %/,%,$(dir $(CURDIR)/$(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST))))

# Disable implicit rules
ifeq ($(filter -r,$(MAKEFLAGS)),)
  MAKEFLAGS += -r
endif

PLATFORMS_PATH := $(TOP)/platforms
FILES_PATH := $(TOP)/files
BUILD_DIR := build
BUILD_PATH := $(TOP)/$(BUILD_DIR)
BUILD_SHARE := $(BUILD_PATH)/share

-include $(wildcard $(PLATFORMS_PATH)/*.mk)

OPENWRT_VERSION := 18.06.1

PLATFORMS := $(patsubst $(PLATFORMS_PATH)/%.mk,%,$(wildcard $(PLATFORMS_PATH)/*.mk))

# Function that returns the URL to the OpenWrt SDK download for a platform
# Usage: $(call platform_openwrt_sdk_url_tpl,<platform>)
platform_openwrt_sdk_url_tpl = https://downloads.openwrt.org/releases/$(OPENWRT_VERSION)/targets/$(PLATFORM_$(1)_CHIP)/$(or $(PLATFORM_$(1)_SPEC),generic)/openwrt-sdk-$(OPENWRT_VERSION)-$(PLATFORM_$(1)_CHIP)$(if $(PLATFORM_$(1)_SPEC),-$(PLATFORM_$(1)_SPEC),)_gcc-7.3.0_$(or $(PLATFORM_$(1)_ABI),musl).Linux-x86_64.tar.xz
platform_sdk_tpl = $(PLATFORM_$(1)_CHIP)$(if $(PLATFORM_$(1)_SPEC),-$(PLATFORM_$(1)_SPEC),)
platform_sdk_url_tpl = SDK_$(call platform_sdk_tpl,$(1))_URL := $(call platform_openwrt_sdk_url_tpl,$(1))
set_sdk_download_urls := $(foreach platform,$(PLATFORMS),$(eval $(call platform_sdk_url_tpl,$(platform))))

ALL_PLATFORMS := $(patsubst %,$(BUILD_DIR)/.%.built,$(PLATFORMS))
ALL_CONFIGS   := $(patsubst %,$(BUILD_DIR)/.%.config,$(PLATFORMS))
ALL_DOWNLOADS := $(patsubst %,$(BUILD_DIR)/.%.download,$(PLATFORMS))
ALL_SDKS      := $(patsubst %,$(BUILD_DIR)/.%.sdk,$(PLATFORMS))

# Phony targets for each platform.
# Results in, for gl_b1300, these targets: gl_b1300 gl_b1300.sdk gl_b1300.build
ALL_BUILD_TARGETS    := $(patsubst %,%.build,$(PLATFORMS))
ALL_SDK_TARGETS      := $(patsubst %,%.sdk,$(PLATFORMS))
ALL_PLATFORM_TARGETS := $(PLATFORMS)

# File/directory targets
ALL_PLATFORM_SDK_TARGETS := $(patsubst %,$(BUILD_PATH)/%/sdk,$(PLATFORMS))
ALL_SDK_UNTAR_TARGETS := $(sort $(foreach platform,$(PLATFORMS),$(BUILD_PATH)/sdk/$(call platform_sdk_tpl,$(platform))))
ALL_SDK_TAR_TARGETS := $(addsuffix .tar.xz,$(ALL_SDK_UNTAR_TARGETS))
ALL_BUILD_DIR_TARGETS := $(addprefix $(BUILD_PATH)/,$(PLATFORMS))

all: $(ALL_PLATFORM_TARGETS)

.PHONY: all distclean clean $(ALL_PLATFORM_TARGETS) $(ALL_BUILD_TARGETS) $(ALL_SDK_TARGETS)

clean:
	rm -rfv $(BUILD_PATH)/out
	rm -rfv $(patsubst %,$(BUILD_PATH)/%,$(PLATFORMS))
	rm -rfv $(patsubst %,$(BUILD_PATH)/.%.*,$(PLATFORMS))

distclean:
	rm -rfv $(BUILD_PATH)

$(BUILD_PATH):
	mkdir -p $@

$(BUILD_PATH)/sdk: $(BUILD_PATH)
	mkdir -p $@

$(ALL_BUILD_DIR_TARGETS): $(BUILD_PATH)
	mkdir -p $@

$(BUILD_SHARE): $(BUILD_PATH)
	mkdir -p $@/build_dir $@/feeds $@/dl

$(ALL_SDK_TAR_TARGETS): $(BUILD_PATH)/sdk/%.tar.xz: $(BUILD_PATH)/sdk
	wget -O $@ $(SDK_$*_URL)

$(addsuffix /Makefile,$(ALL_SDK_UNTAR_TARGETS)): $(BUILD_PATH)/sdk/%/Makefile: $(BUILD_PATH)/sdk/%.tar.xz $(BUILD_SHARE)
	mkdir -p $(BUILD_PATH)/sdk/$*
	tar -C $(BUILD_PATH)/sdk/$* --strip-components=1 -xf $(BUILD_PATH)/sdk/$*.tar.xz
	cd $(BUILD_PATH)/sdk/$* && \
	ln -sf $(FILES_PATH)/feeds.conf feeds.conf && \
	ln -sf $(BUILD_SHARE)/feeds feeds && \
	rm -rf build_dir dl && \
	ln -sf $(BUILD_SHARE)/build_dir build_dir && \
	ln -sf $(BUILD_SHARE)/dl dl && \
	./scripts/feeds update -a && \
	./scripts/feeds install unum && \
	./staging_dir/host/bin/usign -G -s ./key-build -p ./key-build.pub -c "Local build key"

.SECONDEXPANSION:
$(ALL_PLATFORM_SDK_TARGETS): $(BUILD_PATH)/%/sdk: $(BUILD_PATH)/% $(BUILD_PATH)/sdk/$$(call platform_sdk_tpl,%)/Makefile
	ln -sf $(BUILD_PATH)/sdk/$(call platform_sdk_tpl,$*) $@

$(BUILD_DIR)/%/.config: $(BUILD_PATH) $(BUILD_DIR)/.%.sdk | Makefile $(wildcard $(PLATFORMS_PATH)/%*)
	mkdir -p $(BUILD_DIR)/$*
	if [ -e "$(PLATFORMS_PATH)/$*.baseconfig" ]; then \
		cp -f "$(PLATFORMS_PATH)/$*.baseconfig" $@;   \
	fi
	cat "$(PLATFORMS_PATH)/minim.baseconfig" >> $@
	cat "$(PLATFORMS_PATH)/$*.diffconfig" >> $@
	cp -fv $@ $(BUILD_DIR)/$*/sdk/.config
	make -C $(BUILD_DIR)/$*/sdk defconfig
	cp -fv $@ $@.pre
	cp -fv $(BUILD_DIR)/$*/sdk/.config $@

$(ALL_SDKS): $(BUILD_DIR)/.%.sdk: $(BUILD_PATH)/%/sdk
	touch $@

$(ALL_CONFIGS): $(BUILD_DIR)/.%.config: $(BUILD_DIR)/%/.config
	touch $@

$(ALL_DOWNLOADS): $(BUILD_DIR)/.%.download: $(BUILD_DIR)/.%.config
	make -C $(BUILD_DIR)/$*/sdk download
	touch $@

$(ALL_PLATFORMS): $(BUILD_DIR)/.%.built: $(BUILD_DIR)/.%.download
	make -C $(BUILD_DIR)/$*/sdk V=s -j1
	touch $@

$(ALL_PLATFORM_TARGETS): %: %.sdk %.build

$(ALL_BUILD_TARGETS): %.build: $(BUILD_DIR)/.%.built
	mkdir -p $(BUILD_PATH)/out
	cp -fv $(BUILD_PATH)/$*/sdk/bin/targets/*/*/minim*.bin $(BUILD_PATH)/out
	cp -fv $(BUILD_PATH)/$*/sdk/bin/packages/*/minim/unum*.ipk $(BUILD_PATH)/out

$(ALL_SDK_TARGETS): %.sdk: $(BUILD_DIR)/.%.sdk
