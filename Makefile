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
OPENWRT_VERSION := v18.06.1
OPENWRT_GIT_URL := https://github.com/openwrt/openwrt
# Revision or version of Minim's OpenWrt feed to use
MINIM_FEED_VERSION := df504482cab6438abf56318beb93065dbc2905a6
MINIM_FEED_GIT_URL := https://github.com/MinimSecure/minim-openwrt-feed

# Build directory, relative to $(TOP)
BUILD_DIR   := build
# Absolute path to the build directory
BUILD_PATH  := $(TOP)/$(BUILD_DIR)

# Platform-specific Makefiles and OpenWrt buildroot configs
PLATFORMS_PATH := $(TOP)/platforms


# Each platform-specific .mk file in the platforms/ directory is expected to
# define specific variables which are used throughout the rest of the build
-include $(wildcard $(PLATFORMS_PATH)/*.mk)


# Chipset names are dynamically generated from files in $(PLATFORMS_PATH) that
# have the filename suffix ".config.seed"
CHIPSETS := $(patsubst $(PLATFORMS_PATH)/%.config.seed,%,$(wildcard $(PLATFORMS_PATH)/*.config.seed))
# Platform names are dynamically generated from files in $(PLATFORMS_PATH) that
# have the filename suffix ".mk"
PLATFORMS := $(patsubst $(PLATFORMS_PATH)/%.mk,%,$(wildcard $(PLATFORMS_PATH)/*.mk))

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
#   ipq40xx.toolchain   Build the toolchain for this chipset
ALL_CHIPSET_TOOLCHAIN_TARGETS := $(patsubst %,%.toolchain,$(CHIPSETS))
ALL_CHIPSET_CLEAN_TARGETS     := $(patsubst %,%.clean,$(CHIPSETS))
ALL_CHIPSET_BUILD_TARGETS     := $(CHIPSETS)

ALL_PLATFORM_TARGETS := $(ALL_PLATFORM_BUILD_TARGETS) \
                        $(ALL_PLATFORM_SDK_TARGETS) \
                        $(ALL_PLATFORM_CLEAN_TARGETS) \
                        $(ALL_PLATFORM_TOOLCHAIN_TARGETS)
ALL_CHIPSET_TARGETS :=  $(ALL_CHIPSET_BUILD_TARGETS) \
                        $(ALL_CHIPSET_CLEAN_TARGETS) \
                        $(ALL_CHIPSET_TOOLCHAIN_TARGETS)

# Real (not phony) targets
ALL_PLATFORMS  := $(patsubst %,$(BUILD_DIR)/.%.built,$(PLATFORMS))
ALL_CONFIGS    := $(patsubst %,$(BUILD_DIR)/.%.config,$(PLATFORMS))
ALL_SDKS       := $(patsubst %,$(BUILD_DIR)/.%.sdk,$(PLATFORMS))
ALL_TOOLCHAINS := $(patsubst %,$(BUILD_DIR)/.%.toolchain,$(PLATFORMS))

ALL_BUILD_DIRS := $(addprefix $(BUILD_PATH)/,$(PLATFORMS))

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

$(ALL_CHIPSET_TOOLCHAIN_TARGETS): %.toolchain: $$(addsuffix .toolchain,$$(CHIPSET_%_PLATFORMS))

$(ALL_CHIPSET_BUILD_TARGETS): %: $$(CHIPSET_%_PLATFORMS)


$(ALL_PLATFORM_CLEAN_TARGETS): %.clean:
	rm -rfv $(BUILD_PATH)/$*
	rm -rfv $(BUILD_PATH)/.$*.*

$(ALL_PLATFORM_BUILD_TARGETS): %: $(BUILD_DIR)/.%.built
	mkdir -p $(BUILD_PATH)/out
	cp -fv $(BUILD_PATH)/$*/sdk/bin/targets/*/*/minim*.bin $(BUILD_PATH)/out
	cp -fv $(BUILD_PATH)/$*/sdk/bin/packages/*/minim/unum*.ipk $(BUILD_PATH)/out

$(ALL_PLATFORM_SDK_TARGETS): %.sdk: $(BUILD_DIR)/.%.sdk

$(ALL_PLATFORM_TOOLCHAIN_TARGETS): %.toolchain: $(BUILD_DIR)/.%.toolchain


$(BUILD_PATH):
	mkdir -p $@

$(ALL_BUILD_DIRS): $(BUILD_PATH)
	mkdir -p $@
	touch $^

$(BUILD_PATH)/sdk:
	mkdir -p $(dir $@)
	git clone -b $(OPENWRT_VERSION) --depth=1 \
		$(OPENWRT_GIT_URL) \
		$@; \
	cd $@ && \
		cp -f feeds.conf.default feeds.conf && \
		echo 'src-git minim $(MINIM_FEED_GIT_URL)^$(or $(MINIM_FEED_VERSION),master)' >> feeds.conf && \
		./scripts/feeds update -a \
		./scripts/feeds install -a
	touch $@ $^

$(ALL_SDKS): $(BUILD_DIR)/.%.sdk: $(BUILD_PATH)/sdk $(BUILD_PATH)/%
	ln -sf $(BUILD_PATH)/sdk $(BUILD_PATH)/$*/sdk
	touch $@ $^

$(ALL_CONFIGS): $(BUILD_DIR)/.%.config: $(BUILD_DIR)/.%.sdk
	cd $(BUILD_PATH)/$*/sdk && \
		./scripts/feeds update -a && \
		./scripts/feeds install -a
	if [ -e "$(PLATFORMS_PATH)/$*.baseconfig" ]; then \
		cp -f "$(PLATFORMS_PATH)/$*.baseconfig" $(BUILD_PATH)/$*/.config; \
	else \
		rm -f $(BUILD_PATH)/$*/.config; \
	fi
	cat "$(PLATFORMS_PATH)/minim.baseconfig" >> $(BUILD_PATH)/$*/.config
	cat "$(PLATFORMS_PATH)/$*.diffconfig" >> $(BUILD_PATH)/$*/.config
	cp -f $(BUILD_PATH)/$*/.config $(BUILD_PATH)/$*/sdk/.config
	make -C $(BUILD_PATH)/$*/sdk defconfig
	cp -f $(BUILD_PATH)/$*/.config $(BUILD_PATH)/$*/.config.pre
	cp -f $(BUILD_PATH)/$*/sdk/.config $(BUILD_PATH)/$*/.config
	touch $@ $^

$(ALL_TOOLCHAINS): $(BUILD_DIR)/.%.toolchain: $(BUILD_DIR)/.%.config
	cp -f $(BUILD_PATH)/$*/.config $(BUILD_PATH)/$*/sdk/.config
	make -C $(BUILD_PATH)/$*/sdk V=s toolchain/compile
	rm -rf $(BUILD_PATH)/$*/sdk/build_dir/toolchain-*/**/*
	touch $@ $^

$(ALL_PLATFORMS): $(BUILD_DIR)/.%.built: $(BUILD_DIR)/.%.toolchain
	cp -f $(BUILD_PATH)/$*/.config $(BUILD_PATH)/$*/sdk/.config
	make -C $(BUILD_PATH)/$*/sdk V=s
	touch $@
