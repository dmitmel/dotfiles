#!/usr/bin/env bash

find_dotfiles_dir() {
  local readlink
  # readlink=$(which greadlink || which readlink)
  local script_path"=${(%):-%x}"

  if [[ -n "$script_path" && -x "$readlink" ]]; then
    script_path=$($readlink -f "$script_path")
    DOTFILES_DIR=$(dirname "$script_path")
  else
    for prefix in "$HOME/" "$HOME/." "/usr/share/" "/usr/local/share/"; do
      local dotfiles_dir="${prefix}dotfiles"
      if [[ -d "$dotfiles_dir" ]]; then
        DOTFILES_DIR="$dotfiles_dir"
        break
      fi
    done
  fi

  if [[ -d $DOTFILES_DIR ]]; then
    export DOTFILES_DIR
  else
    echo "dotfiles directory not found"
  fi
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
