# https://tech.davis-hansson.com/p/make/
SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

.PHONY: all clean

OUT_DIR := out
OUT_FILES := iterm.itermcolors kitty.conf vim.vim setvtrgb.txt zsh.zsh termux.properties variables.css prismjs-theme.css vscode-colorCustomizations.json xfce4-terminal.theme

all: $(OUT_DIR) $(addprefix $(OUT_DIR)/,$(OUT_FILES))

clean:
	rm -rv $(OUT_DIR)

$(OUT_DIR):
	mkdir -p $@

$(OUT_DIR)/%: %.py _theme.py $(OUT_DIR)
	python3 ./$< > $@

$(OUT_DIR)/prismjs-theme.css: prismjs-theme-src.css
