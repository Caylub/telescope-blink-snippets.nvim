.PHONY: test lint doc clean

TESTS_DIR := tests
MINIMAL_INIT := $(TESTS_DIR)/minimal_init.lua

test:
	@nvim --headless -u $(MINIMAL_INIT) -c "PlenaryBustedDirectory $(TESTS_DIR)/ {minimal_init = '$(MINIMAL_INIT)'}"

lint:
	@luacheck lua/ tests/ --config .luacheckrc

doc:
	@nvim --headless -c "helptags doc/" -c "quit"

clean:
	@rm -f doc/tags
