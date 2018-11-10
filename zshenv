#!/usr/bin/env zsh

DOTFILES_PATH="${0:h}"

for script in functions path exports; do
  source "$DOTFILES_PATH/lib/$script.zsh"
  source_if_exists "$DOTFILES_PATH/custom/$script.zsh"
done
