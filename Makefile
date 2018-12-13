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

PLATFORMS_PATH := $(TOP)/platforms
BUILD_DIR := build
BUILD_PATH := $(TOP)/$(BUILD_DIR)
OPENWRT_PATH := $(TOP)/openwrt

CONFIGS := $(filter-out $(PLATFORMS_PATH)/minim.baseconfig,$(wildcard $(PLATFORMS_PATH)/*.baseconfig))
ALL_CONFIGS := $(subst baseconfig,config,\
	$(subst $(PLATFORMS_PATH),$(BUILD_DIR),$(CONFIGS)))
ALL_PLATFORMS := $(patsubst $(BUILD_DIR)/%.config,%,$(ALL_CONFIGS))
ALL_TARGETS := $(patsubst %,$(BUILD_DIR)/.%.built,$(ALL_PLATFORMS))

all: build-all

.PHONY: all clean build-all

clean:
	rm -rfv $(BUILD_PATH)

build-all: $(ALL_TARGETS)
	mkdir -p $(BUILD_PATH)/out
	cp -fv $(OPENWRT_PATH)/bin/targets/*/*/minim*.bin $(BUILD_PATH)/out
	cp -fv $(OPENWRT_PATH)/bin/packages/*/minim/unum*.ipk $(BUILD_PATH)/out

$(BUILD_DIR):
	mkdir -p $@

$(ALL_CONFIGS): $(BUILD_DIR)/%.config: $(BUILD_DIR)
	if [ -e "$(PLATFORMS_PATH)/$*.baseconfig" ]; then \
		cp -f "$(PLATFORMS_PATH)/$*.baseconfig" $@;   \
	fi
	cat "$(PLATFORMS_PATH)/minim.baseconfig" >> $@
	cat "$(PLATFORMS_PATH)/$*.diffconfig" >> $@
	cp -fv $@ $(OPENWRT_PATH)/.config
	make -C $(OPENWRT_PATH) defconfig
	cp -fv $@ $@.pre
	cp -fv $(OPENWRT_PATH)/.config $@

$(ALL_PLATFORMS): %: $(BUILD_DIR)/.%.built

$(ALL_TARGETS): $(BUILD_DIR)/.%.built: $(BUILD_DIR)/%.config
	cp -fv $(BUILD_DIR)/$*.config $(OPENWRT_PATH)/.config
	make -C $(OPENWRT_PATH)
	touch $@
