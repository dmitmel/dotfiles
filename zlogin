#!/usr/bin/env zsh

if [[ -n "$DOTFILES_PATH" ]]; then
  python "$DOTFILES_PATH/welcome/main.py"
fi
