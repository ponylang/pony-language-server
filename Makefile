config ?= release

PACKAGE := lsp
GET_DEPENDENCIES_WITH := corral fetch
CLEAN_DEPENDENCIES_WITH := corral clean
PONYC ?= ponyc
COMPILE_WITH := corral run -- $(PONYC)


BUILD_DIR ?= build/$(config)
SRC_DIR ?= $(PACKAGE)
TEST_SRC_DIR ?= $(PACKAGE)/test
binary := $(BUILD_DIR)/pony-lsp
tests_binary := $(BUILD_DIR)/test
docs_dir := build/$(BUNDLE)-docs

ifdef config
	ifeq (,$(filter $(config),debug release))
    $(error Unknown configuration "$(config)")
  endif
endif

PONYC ?= ponyc

ifeq ($(config),release)
	PONYC := $(COMPILE_WITH)
else
	PONYC := $(COMPILE_WITH) --debug
endif

ifneq ($(arch),)
  arch_arg := --cpu $(arch)
endif

SOURCE_FILES := $(shell find $(SRC_DIR) -name *.pony)

all: $(binary) test
	$(MAKE) -C client_vscode

test: $(tests_binary)
	$^ --exclude=integration

$(tests_binary): $(SOURCE_FILES) | $(BUILD_DIR)
	$(GET_DEPENDENCIES_WITH)
	$(PONYC) -o $(BUILD_DIR) --bin-name $(notdir $(tests_binary)) $(TEST_SRC_DIR)

$(binary): $(SOURCE_FILES) | $(BUILD_DIR)
	$(GET_DEPENDENCIES_WITH)
	$(PONYC) -o $(BUILD_DIR) --bin-name $(notdir $(binary)) $(SRC_DIR)

clean:
	$(CLEAN_DEPENDENCIES_WITH)
	rm -rf $(BUILD_DIR)
	$(MAKE) -C client_vscode clean

$(docs_dir): $(SOURCE_FILES)
	rm -rf $(docs_dir)
	$(GET_DEPENDENCIES_WITH)
	$(PONYC) --docs-public --pass=docs --output build $(SRC_DIR)

docs: $(docs_dir)

.coverage:
	mkdir -p .coverage

coverage: .coverage $(tests_binary)
	kcov --include-pattern="$(SRC_DIR)" --exclude-pattern="*/test/*.pony,*/_test.pony" .coverage $(tests_binary)

TAGS:
	ctags --recurse=yes $(SRC_DIR)


$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

.PHONY: all clean TAGS test
