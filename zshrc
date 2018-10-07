#!/usr/bin/env zsh

if [[ -n "$DOTFILES_PATH" ]]; then
  for script in functions path exports oh-my-zsh aliases widgets theme; do
    source "$DOTFILES_PATH/lib/$script.zsh"
    source_if_exists "$DOTFILES_PATH/custom/$script.zsh"
  done

  run_before rbenv 'eval "$(rbenv init -)"'
  run_before sdk 'source_if_exists "$SDKMAN_DIR/bin/sdkman-init.sh"'

  python "$DOTFILES_PATH/welcome/main.py"
else
  echo "please, set DOTFILES_PATH to the path to your dotfiles directory" >&2
fi
