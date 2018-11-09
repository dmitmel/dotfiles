#!/usr/bin/env zsh

if [[ -n "$DOTFILES_PATH" ]]; then
  for script in functions path exports; do
    source "$DOTFILES_PATH/lib/$script.zsh"
    source_if_exists "$DOTFILES_PATH/custom/$script.zsh"
  done
else
  echo "please, set DOTFILES_PATH to the path to your dotfiles directory" >&2
fi
