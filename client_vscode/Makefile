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
EXTENSION := $(BUILD_DIR)/pony-lsp-$(PONY_VERSION).vsix
SOURCE_FILES := $(shell find $(SRC_DIR) -name *.ts)

all: $(EXTENSION)

$(EXTENSION): $(SOURCE_FILES) pony-lsp node_modules
	vsce package -o $(BUILD_DIR) $(PONY_VERSION)

node_modules:
	npm install

pony-lsp: $(BUILD_DIR)/pony-lsp
	cp $(BUILD_DIR)/pony-lsp pony-lsp

$(BUILD_DIR)/pony-lsp:
	$(MAKE) -C ..

clean:
	rm -rf dist $(BUILD_DIR)


.PHONY: clean
