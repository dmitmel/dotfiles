#!/usr/bin/env zsh

DOTFILES_PATH="${0:h}"

for script in functions path exports zgen aliases palette theme; do
  source "$DOTFILES_PATH/lib/$script.zsh"
  source_if_exists "$DOTFILES_PATH/custom/$script.zsh"
done

if command_exists rbenv; then
  eval "$(rbenv init -)"
fi

python "$DOTFILES_PATH/welcome/main.py"
