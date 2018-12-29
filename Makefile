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
DOWNLOAD_PATH := $(TOP)/dl
BUILD_SHARE := $(BUILD_PATH)/share

-include $(wildcard $(PLATFORMS_PATH)/*.mk)

OPENWRT_VERSION := 18.06.1

PLATFORMS := $(patsubst $(PLATFORMS_PATH)/%.mk,%,$(wildcard $(PLATFORMS_PATH)/*.mk))

platform_sdk_tpl = $(PLATFORM_$(1)_CHIP)$(if $(PLATFORM_$(1)_SPEC),-$(PLATFORM_$(1)_SPEC),)

ALL_PLATFORMS     := $(patsubst %,$(BUILD_DIR)/.%.built,$(PLATFORMS))
ALL_CONFIGS       := $(patsubst %,$(BUILD_DIR)/.%.config,$(PLATFORMS))
ALL_SDKS          := $(patsubst %,$(BUILD_DIR)/.%.sdk,$(PLATFORMS))
ALL_TOOLCHAINS    := $(patsubst %,$(BUILD_DIR)/.%.toolchain,$(PLATFORMS))

# Phony targets for each platform.
# Results in, for gl_b1300, these targets: gl_b1300 gl_b1300.sdk gl_b1300.build
ALL_BUILD_TARGETS     := $(patsubst %,%.build,$(PLATFORMS))
ALL_SDK_TARGETS       := $(patsubst %,%.sdk,$(PLATFORMS))
ALL_TOOLCHAIN_TARGETS := $(patsubst %,%.toolchain,$(PLATFORMS))
ALL_PLATFORM_TARGETS  := $(PLATFORMS)

# File/directory targets
ALL_PLATFORM_SDK_TARGETS := $(patsubst %,$(BUILD_PATH)/%/sdk,$(PLATFORMS))
ALL_BUILD_DIR_TARGETS := $(addprefix $(BUILD_PATH)/,$(PLATFORMS))

all: $(ALL_PLATFORM_TARGETS)

.PHONY: all distclean clean $(ALL_PLATFORM_TARGETS) $(ALL_BUILD_TARGETS) $(ALL_SDK_TARGETS)

clean:
	rm -rfv $(BUILD_PATH)/out
	rm -rfv $(patsubst %,$(BUILD_PATH)/%,$(PLATFORMS))
	rm -rfv $(patsubst %,$(BUILD_PATH)/.%.*,$(PLATFORMS))

distclean:
	rm -rfv $(BUILD_PATH) $(DOWNLOAD_PATH)

$(ALL_PLATFORM_TARGETS): %: %.sdk %.toolchain %.build

$(ALL_BUILD_TARGETS): %.build: $(BUILD_DIR)/.%.built
	mkdir -p $(BUILD_PATH)/out
	cp -fv $(BUILD_PATH)/$*/sdk/bin/targets/*/*/minim*.bin $(BUILD_PATH)/out
	cp -fv $(BUILD_PATH)/$*/sdk/bin/packages/*/minim/unum*.ipk $(BUILD_PATH)/out

$(ALL_SDK_TARGETS): %.sdk: $(BUILD_DIR)/.%.sdk

$(ALL_TOOLCHAIN_TARGETS): %.toolchain: $(BUILD_DIR)/.%.toolchain

$(BUILD_PATH):
	mkdir -p $@

$(BUILD_PATH)/sdk: $(BUILD_PATH) $(BUILD_SHARE)
	mkdir -p $@
	git clone -b v18.06.1 --depth=1 https://github.com/openwrt/openwrt $(BUILD_PATH)/sdk
	cd $(BUILD_PATH)/sdk &&                           \
		ln -sf $(FILES_PATH)/feeds.conf feeds.conf && \
		ln -sf $(BUILD_SHARE)/feeds feeds &&          \
		rm -rf build_dir dl &&                        \
		ln -sf $(BUILD_SHARE)/build_dir build_dir &&  \
		ln -sf $(DOWNLOAD_PATH) dl &&                 \
		./scripts/feeds update -a &&                  \
		./scripts/feeds install -a
	touch $@

$(ALL_BUILD_DIR_TARGETS): $(BUILD_PATH)
	mkdir -p $@

$(DOWNLOAD_PATH):
	mkdir -p $@

$(BUILD_SHARE): $(BUILD_PATH)
	mkdir -p $@/build_dir $@/feeds $@/dl

$(BUILD_DIR)/.cloned: $(BUILD_PATH)/sdk $(DOWNLOAD_PATH)
	touch $@

$(ALL_SDKS): $(BUILD_DIR)/.%.sdk: $(BUILD_DIR)/.cloned
	mkdir -p $(BUILD_PATH)/$*
	ln -sf $(BUILD_PATH)/sdk $(BUILD_PATH)/$*/sdk
	touch $@ $^

$(ALL_CONFIGS): $(BUILD_DIR)/.%.config: $(BUILD_DIR)/.cloned $(BUILD_DIR)/.%.sdk $(BUILD_PATH)/%
	if [ -e "$(PLATFORMS_PATH)/$*.baseconfig" ]; then                     \
		cp -f "$(PLATFORMS_PATH)/$*.baseconfig" $(BUILD_PATH)/$*/.config; \
	else                                                                  \
		rm -f $(BUILD_PATH)/$*/.config;                                   \
	fi
	cat "$(PLATFORMS_PATH)/minim.baseconfig" >> $(BUILD_PATH)/$*/.config
	cat "$(PLATFORMS_PATH)/$*.diffconfig" >> $(BUILD_PATH)/$*/.config
	cp -f $(BUILD_PATH)/$*/.config $(BUILD_PATH)/$*/sdk/.config
	make -C $(BUILD_PATH)/$*/sdk defconfig
	cp -f $(BUILD_PATH)/$*/.config $(BUILD_PATH)/$*/.config.pre
	cp -f $(BUILD_PATH)/$*/sdk/.config $(BUILD_PATH)/$*/.config
	touch $@ $^

$(ALL_TOOLCHAINS): $(BUILD_DIR)/.%.toolchain: $(BUILD_DIR)/.%.config $(BUILD_DIR)/.%.sdk $(BUILD_DIR)/.cloned
	cp -f $(BUILD_PATH)/$*/.config $(BUILD_PATH)/$*/sdk/.config
	make -C $(BUILD_PATH)/$*/sdk V=s -j1 toolchain/compile
	touch $@

$(ALL_PLATFORMS): $(BUILD_DIR)/.%.built: $(BUILD_DIR)/.%.toolchain
	cp -f $(BUILD_PATH)/$*/.config $(BUILD_PATH)/$*/sdk/.config
	make -C $(BUILD_PATH)/$*/sdk V=s -j1
	touch $@
