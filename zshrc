#!/usr/bin/env zsh

if [[ -n "$DOTFILES_PATH" && -n "$OH_MY_ZSH_PATH" ]]; then
  for script in functions path exports aliases oh-my-zsh widgets; do
    source "$DOTFILES_PATH/lib/$script.zsh"
  done

  source_if_exists "$ZSH/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh"

  run_before rbenv 'eval "$(rbenv init -)"'
  run_before sdk 'source_if_exists "$SDKMAN_DIR/bin/sdkman-init.sh"'
  run_before yarn 'source_if_exists "$(yarn global dir)/node_modules/tabtab/.completions/yarn.zsh"'

  python "$DOTFILES_PATH/welcome/main.py"
else
  [[ -z "$DOTFILES_PATH" ]] && echo "please, set DOTFILES_PATH to the path to your dotfiles directory" >&2
  [[ -z "$OH_MY_ZSH_PATH" ]] && echo "please, set OH_MY_ZSH_PATH to the path to your Oh My Zsh directory" >&2
fi
