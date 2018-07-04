#!/usr/bin/env zsh

find_dotfiles_dir() {
  export DOTFILES_DIR

  for prefix in "$HOME/." "/usr/share/" "/usr/local/share/"; do
    DOTFILES_DIR="${prefix}dotfiles"
    [[ -d "$DOTFILES_DIR" ]] && return
  done

  local script_path="$(realpath "${(%):-%x}")"
  DOTFILES_DIR="$(dirname "$script_path")"
}

find_dotfiles_dir

for script in functions path exports aliases oh-my-zsh widgets; do
  source "${DOTFILES_DIR}/lib/${script}.zsh"
done

source_if_exists "$ZSH/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh"
run_before rbenv 'eval "$(rbenv init -)"'
run_before sdk 'source_if_exists "$SDKMAN_DIR/bin/sdkman-init.sh"'
run_before yarn 'source_if_exists "$(yarn global dir)/node_modules/tabtab/.completions/yarn.zsh"'
