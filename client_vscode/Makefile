PONY_VERSION := 0.58.4

config ?= release
ifdef config
	ifeq (,$(filter $(config),debug release))
    $(error Unknown configuration "$(config)")
  endif
endif


BUILD_DIR := ../build/$(config)
DIST_DIR := dist
SRC_DIR := src
EXTENSION_JS := $(DIST_DIR)/extension.js
EXTENSION := pony-lsp-$(PONY_VERSION).vsix
SOURCE_FILES := $(shell find $(SRC_DIR) -name *.ts)

all: $(EXTENSION)

$(EXTENSION): $(SOURCE_FILES) $(BUILD_DIR)/pony-lsp node_modules
	vsce package $(PONY_VERSION)

node_modules:
	npm install

clean:
	rm -f $(EXTENSION)
	rm -rf dist

$(BUILD_DIR)/pony-lsp:
	$(MAKE) -C ..

.PHONY: clean
