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
export TOP := $(patsubst %/,%,$(dir $(CURDIR)/$(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST))))

# Disable implicit rules
ifeq ($(filter -r,$(MAKEFLAGS)),)
  MAKEFLAGS += -r
endif

# Version of OpenWrt to build
OPENWRT_VERSION := v18.06.2
OPENWRT_GIT_URL := https://github.com/openwrt/openwrt
# Revision of Minim's OpenWrt feed to use
MINIM_FEED_VERSION := v2019.2.0
MINIM_FEED_GIT_URL := https://github.com/MinimSecure/minim-openwrt-feed

# Build directory, relative to $(TOP)
BUILD_DIR   := build
# Directory containing OpenWrt buildroot, shared by all platforms
SDK_DIR     := $(BUILD_DIR)/sdk
# Directory containing built artifacts
OUT_DIR     := $(BUILD_DIR)/out

# Absolute path to the build directory
BUILD_PATH  := $(TOP)/$(BUILD_DIR)
# Platform-specific Makefiles and OpenWrt buildroot configs
PLATFORMS_PATH := $(TOP)/platforms

# A "platform" is a specific device, such as `gl_b1300` (for GL.iNet B1300)
# A "chipset" is a chipset that some device uses, such as `ipq40xx` (which is
# the GL.iNet B1300 chipset).


# Chipset names are dynamically generated from files in $(PLATFORMS_PATH) that
# have the filename suffix ".config.seed"
CHIPSETS := $(patsubst $(PLATFORMS_PATH)/%.config.seed,%,$(wildcard $(PLATFORMS_PATH)/*.config.seed))
# Platform names are dynamically generated from files in $(PLATFORMS_PATH) that
# have the filename suffix ".mk"
PLATFORMS := $(patsubst $(PLATFORMS_PATH)/%.diffconfig,%,$(wildcard $(PLATFORMS_PATH)/*.diffconfig))

# Generate new variables for each chipset containing a list of the platforms
# using that chipset.
# For example, $(CHIPSET_ipq40xx_PLATFORMS) will contain: gl_b1300
platform_to_chipset_tpl = $(patsubst %.config.seed,%,$(shell readlink $(PLATFORMS_PATH)/$(1).baseconfig))
chipset_platforms_tpl = CHIPSET_$(call platform_to_chipset_tpl,$(1))_PLATFORMS += $(1)
chipset_platforms_eval := $(foreach platform,$(PLATFORMS),$(eval $(call chipset_platforms_tpl,$(platform))))

# Phony targets generated for each platform
# Results in, for gl_b1300 (ipq40xx chipset), these targets:
#   gl_b1300            Build everything for this platform
#   gl_b1300.clean      Clean build related files for this platform only
#   gl_b1300.sdk        Check out and prepare an OpenWrt buildroot
#   gl_b1300.toolchain  Build only the toolchain for the given platform
ALL_PLATFORM_SDK_TARGETS       := $(patsubst %,%.sdk,$(PLATFORMS))
ALL_PLATFORM_TOOLCHAIN_TARGETS := $(patsubst %,%.toolchain,$(PLATFORMS))
ALL_PLATFORM_CLEAN_TARGETS     := $(patsubst %,%.clean,$(PLATFORMS))
ALL_PLATFORM_BUILD_TARGETS     := $(PLATFORMS)

# Phony chipset targets which operate on all platforms for that chipset.
# Continuing the gl_b1300 example, these targets will also be created:
#   ipq40xx             Build everything for all platforms using this chipset
#   ipq40xx.clean		Clean build files for all platforms for this chipset
#   ipq40xx.sdk         Check out and prepare an OpenWrt buildroot
#   ipq40xx.toolchain   Build the toolchain for this chipset
ALL_CHIPSET_SDK_TARGETS       := $(patsubst %,%.sdk,$(CHIPSETS))
ALL_CHIPSET_TOOLCHAIN_TARGETS := $(patsubst %,%.toolchain,$(CHIPSETS))
ALL_CHIPSET_CLEAN_TARGETS     := $(patsubst %,%.clean,$(CHIPSETS))
ALL_CHIPSET_BUILD_TARGETS     := $(CHIPSETS)

ALL_PLATFORM_TARGETS := $(ALL_PLATFORM_BUILD_TARGETS) \
                        $(ALL_PLATFORM_CLEAN_TARGETS) \
                        $(ALL_PLATFORM_SDK_TARGETS) \
                        $(ALL_PLATFORM_TOOLCHAIN_TARGETS)
ALL_CHIPSET_TARGETS :=  $(ALL_CHIPSET_BUILD_TARGETS) \
                        $(ALL_CHIPSET_CLEAN_TARGETS) \
                        $(ALL_CHIPSET_SDK_TARGETS) \
                        $(ALL_CHIPSET_TOOLCHAIN_TARGETS)

# Real (not phony) targets
ALL_PLATFORMS  := $(patsubst %,$(BUILD_DIR)/.%.built,$(PLATFORMS))
ALL_CONFIGS    := $(patsubst %,$(BUILD_DIR)/.%.config,$(PLATFORMS))
ALL_SDKS       := $(patsubst %,$(BUILD_DIR)/.%.sdk,$(PLATFORMS))
ALL_TOOLCHAINS := $(patsubst %,$(BUILD_DIR)/.%.toolchain,$(PLATFORMS))
ALL_BUILD_DIRS := $(addprefix $(BUILD_DIR)/,$(PLATFORMS))


all: $(ALL_PLATFORM_BUILD_TARGETS)

.PHONY: all distclean clean touch $(ALL_CHIPSET_TARGETS) $(ALL_PLATFORM_TARGETS)

clean:
	rm -rfv $(BUILD_PATH)/out
	rm -rfv $(patsubst %,$(BUILD_PATH)/%,$(PLATFORMS))
	rm -rfv $(patsubst %,$(BUILD_PATH)/.%.*,$(PLATFORMS))

distclean:
	rm -rfv $(BUILD_PATH)


.SECONDEXPANSION:
$(ALL_CHIPSET_CLEAN_TARGETS): %.clean: $$(addsuffix .clean,$$(CHIPSET_%_PLATFORMS))

$(ALL_CHIPSET_SDK_TARGETS): %.sdk: $$(addsuffix .sdk,$$(CHIPSET_%_PLATFORMS))

$(ALL_CHIPSET_TOOLCHAIN_TARGETS): %.toolchain: $$(addsuffix .toolchain,$$(CHIPSET_%_PLATFORMS))

$(ALL_CHIPSET_BUILD_TARGETS): %: $$(CHIPSET_%_PLATFORMS)


$(ALL_PLATFORM_CLEAN_TARGETS): %.clean:
	rm -rfv $(BUILD_PATH)/$*
	rm -rfv $(BUILD_PATH)/.$*.*

$(ALL_PLATFORM_SDK_TARGETS): %.sdk: $(BUILD_DIR)/.%.sdk

$(ALL_PLATFORM_TOOLCHAIN_TARGETS): %.toolchain: $(BUILD_DIR)/.%.toolchain

$(ALL_PLATFORM_BUILD_TARGETS): %: $(BUILD_DIR)/.%.built
	mkdir -p $(OUT_DIR)
	cp -fv $(BUILD_PATH)/$*/sdk/bin/targets/*/*/minim*.bin $(OUT_DIR)
	cp -fv $(BUILD_PATH)/$*/sdk/bin/packages/*/minim/unum*.ipk $(OUT_DIR)


$(BUILD_DIR):
	mkdir -p $@

$(ALL_BUILD_DIRS): $(BUILD_DIR)
	mkdir -p $@
	touch $^

$(SDK_DIR):
	mkdir -p $(dir $@)
	git clone -b $(OPENWRT_VERSION) --depth=1 \
		$(OPENWRT_GIT_URL) $@
	cd $@ && \
		cp -f feeds.conf.default feeds.conf && \
		echo 'src-git minim $(MINIM_FEED_GIT_URL)^$(or $(MINIM_FEED_VERSION),master)' >> feeds.conf && \
		./scripts/feeds update -a \
		./scripts/feeds install -a
	touch $@ $^


$(ALL_SDKS): $(BUILD_DIR)/.%.sdk: $(SDK_DIR) $(BUILD_DIR)/%
	ln -sf $(TOP)/$(SDK_DIR) $(BUILD_DIR)/$*/sdk
	touch $@ $^

$(ALL_CONFIGS): $(BUILD_DIR)/.%.config: $(BUILD_DIR)/.%.sdk
	cd $(BUILD_DIR)/$*/sdk && \
		./scripts/feeds update -a && \
		./scripts/feeds install -a
	if [ -e "$(PLATFORMS_PATH)/$*.baseconfig" ]; then \
		cp -f "$(PLATFORMS_PATH)/$*.baseconfig" $(BUILD_DIR)/$*/.config; \
	else \
		rm -f $(BUILD_DIR)/$*/.config; \
	fi
	cat "$(PLATFORMS_PATH)/minim.baseconfig" >> $(BUILD_DIR)/$*/.config
	cat "$(PLATFORMS_PATH)/$*.diffconfig" >> $(BUILD_DIR)/$*/.config
	cp -f $(BUILD_DIR)/$*/.config $(BUILD_DIR)/$*/sdk/.config
	make -C $(BUILD_PATH)/$*/sdk defconfig
	cp -f $(BUILD_DIR)/$*/.config $(BUILD_DIR)/$*/.config.pre
	cp -f $(BUILD_DIR)/$*/sdk/.config $(BUILD_DIR)/$*/.config
	touch $@ $^

$(ALL_TOOLCHAINS): $(BUILD_DIR)/.%.toolchain: $(BUILD_DIR)/.%.config
	cp -f $(BUILD_DIR)/$*/.config $(BUILD_DIR)/$*/sdk/.config
	make -C $(BUILD_PATH)/$*/sdk V=s toolchain/compile
	rm -rf $(BUILD_DIR)/$*/sdk/build_dir/toolchain-*/**/*
	touch $@ $^

$(ALL_PLATFORMS): $(BUILD_DIR)/.%.built: $(BUILD_DIR)/.%.toolchain
	cp -f $(BUILD_DIR)/$*/.config $(BUILD_DIR)/$*/sdk/.config
	make -C $(BUILD_PATH)/$*/sdk V=s
	touch $@
