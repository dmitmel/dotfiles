# https://tech.davis-hansson.com/p/make/
SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

.PHONY: all clean

OUT_DIR := out
OUT_FILES := iterm.itermcolors kitty.conf vim.vim setvtrgb.txt zsh.zsh termux.properties

all: $(OUT_DIR) $(addprefix $(OUT_DIR)/,$(OUT_FILES))

clean:
	rm -rv out

out:
	mkdir -p $@

$(OUT_DIR)/%: %.py
	./$< > $@
