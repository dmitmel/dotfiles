#!/usr/bin/env zsh

DOTFILES_PATH="${0:h}"

for script in functions path exports zgen aliases widgets theme; do
  source "$DOTFILES_PATH/lib/$script.zsh"
  source_if_exists "$DOTFILES_PATH/custom/$script.zsh"
done

lazy_load sdk 'source_if_exists "$SDKMAN_DIR/bin/sdkman-init.sh"'

if command_exists rbenv; then
  eval "$(rbenv init -)"
fi

python "$DOTFILES_PATH/welcome/main.py"
