#!/usr/bin/env zsh

DOTFILES_PATH="${0:h}"

for script in zgen aliases widgets theme; do
  source "$DOTFILES_PATH/lib/$script.zsh"
  source_if_exists "$DOTFILES_PATH/custom/$script.zsh"
done

run_before rbenv 'eval "$(rbenv init -)"'
run_before sdk 'source_if_exists "$SDKMAN_DIR/bin/sdkman-init.sh"'
