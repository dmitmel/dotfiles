#!/usr/bin/env zsh

find_dotfiles_dir() {
  export DOTFILES_DIR

  for prefix in "$HOME/." "/usr/share/" "/usr/local/share/"; do
    DOTFILES_DIR="${prefix}dotfiles"
    [[ -d "$DOTFILES_DIR" ]] && return
  done

  local script_path
  script_path=$(realpath "${(%):-%x}")
  DOTFILES_DIR=$(dirname "$script_path")
}

find_dotfiles_dir

for script in "$DOTFILES_DIR"/{functions,path,exports,aliases,oh-my-zsh}.zsh; do
  source "$script"
done

# rbenv
command_exists rbenv && eval "$(rbenv init -)"
# sdkman
source_if_exists "$SDKMAN_DIR/bin/sdkman-init.sh"
# Yarn completion
source_if_exists "/usr/local/lib/node_modules/yarn-completions/node_modules/tabtab/.completions/yarn.zsh"
