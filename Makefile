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
BUILD_DIR := build
BUILD_PATH := $(TOP)/$(BUILD_DIR)

MODEL ?= gl_b1300

-include $(PLATFORMS_PATH)/$(MODEL).mk

ifeq ($(PLATFORM_NAME),)
	__err := $(error "expected PLATFORM_NAME to not be empty")
endif

PLATFORMS := $(patsubst $(PLATFORMS_PATH)/%.mk,%,$(wildcard $(PLATFORMS_PATH)/*.mk))

ALL_PLATFORMS := $(patsubst %,$(BUILD_DIR)/.%.built,$(PLATFORMS))
ALL_CONFIGS   := $(patsubst %,$(BUILD_DIR)/.%.config,$(PLATFORMS))
ALL_DOWNLOADS := $(patsubst %,$(BUILD_DIR)/.%.download,$(PLATFORMS))
ALL_SDKS      := $(patsubst %,$(BUILD_DIR)/.%.sdk,$(PLATFORMS))

ALL_BUILD_TARGETS    := $(patsubst %,%.build,$(PLATFORMS))
ALL_SDK_TARGETS      := $(patsubst %,%.sdk,$(PLATFORMS))
ALL_PLATFORM_TARGETS := $(PLATFORMS)

PLATFORM_CHIP_SDK_TARGET := $(BUILD_PATH)/sdk/$(PLATFORM_CHIP)
PLATFORM_CHIP_SDK_TAR_TARGET := $(PLATFORM_CHIP_SDK_TARGET).tar.xz
PLATFORM_SDK_TARGET := $(BUILD_PATH)/$(PLATFORM_NAME)/sdk

OPENWRT_PATH := $(PLATFORM_SDK_TARGET)

all: $(MODEL).build

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
	mkdir -p $(BUILD_PATH)/sdk

$(BUILD_PATH)/$(MODEL): $(BUILD_PATH)
	mkdir -p $(BUILD_PATH)/$(MODEL)

$(PLATFORM_CHIP_SDK_TAR_TARGET): $(BUILD_PATH)/sdk
	wget -O $@ $(PLATFORM_SDK)

$(PLATFORM_CHIP_SDK_TARGET)/Makefile: $(PLATFORM_CHIP_SDK_TAR_TARGET)
	mkdir -p $(PLATFORM_CHIP_SDK_TARGET)
	tar -C $(PLATFORM_CHIP_SDK_TARGET) --strip-components=1 -xf $(PLATFORM_CHIP_SDK_TAR_TARGET)
	cd $(PLATFORM_CHIP_SDK_TARGET) && \
	cp -f feeds.conf.default feeds.conf && \
	echo "# Minim open source feed containing Unum agent" >> feeds.conf && \
	echo "src-git minim https://github.com/MinimSecure/minim-openwrt-feed" >> feeds.conf && \
	./scripts/feeds update -a && \
	./scripts/feeds install unum

$(PLATFORM_SDK_TARGET): $(BUILD_PATH)/$(MODEL) $(PLATFORM_CHIP_SDK_TARGET)/Makefile
	ln -sf $(BUILD_PATH)/sdk/$(PLATFORM_CHIP) $@

$(BUILD_DIR)/%/.config: $(BUILD_PATH) $(BUILD_DIR)/.%.sdk | Makefile $(wildcard $(PLATFORMS_PATH)/%*)
	mkdir -p $(BUILD_DIR)/$*
	if [ -e "$(PLATFORMS_PATH)/$*.baseconfig" ]; then \
		cp -f "$(PLATFORMS_PATH)/$*.baseconfig" $@;   \
	fi
	cat "$(PLATFORMS_PATH)/minim.baseconfig" >> $@
	cat "$(PLATFORMS_PATH)/$*.diffconfig" >> $@
	cp -fv $@ $(OPENWRT_PATH)/.config
	make -C $(OPENWRT_PATH) defconfig
	cp -fv $@ $@.pre
	cp -fv $(OPENWRT_PATH)/.config $@

$(ALL_SDKS): $(BUILD_DIR)/.%.sdk: $(BUILD_PATH)/%/sdk
	touch $@

$(ALL_CONFIGS): $(BUILD_DIR)/.%.config: $(BUILD_DIR)/%/.config
	touch $@

$(ALL_DOWNLOADS): $(BUILD_DIR)/.%.download: $(BUILD_DIR)/.%.config
	make -C $(OPENWRT_PATH) download
	touch $@

$(ALL_PLATFORMS): $(BUILD_DIR)/.%.built: $(BUILD_DIR)/.%.download
	make -C $(OPENWRT_PATH) V=s -j1
	touch $@

$(ALL_PLATFORM_TARGETS): %: %.sdk %.build

$(ALL_BUILD_TARGETS): %.build: $(BUILD_DIR)/.%.built
	mkdir -p $(BUILD_PATH)/out
	cp -fv $(OPENWRT_PATH)/bin/targets/*/*/minim*.bin $(BUILD_PATH)/out
	cp -fv $(OPENWRT_PATH)/bin/packages/*/minim/unum*.ipk $(BUILD_PATH)/out

$(ALL_SDK_TARGETS): %.sdk: $(BUILD_DIR)/.%.sdk
