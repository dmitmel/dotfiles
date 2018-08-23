#!/usr/bin/env zsh

configure_oh_my_zsh() {
  export ZSH="$DOTFILES_PATH/oh-my-zsh"

  # see https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
  export ZSH_THEME="agnoster"

  # use hyphen-insensitive completion (makes `_` and `-` interchangeable)
  export HYPHEN_INSENSITIVE="true"

  # enable command auto-correction
  export ENABLE_CORRECTION="true"

  # display red dots while waiting for completion
  export COMPLETION_WAITING_DOTS="true"

  # disable marking untracked files under VCS as dirty (this makes repository
  # status check for large repositories faster)
  export DISABLE_UNTRACKED_FILES_DIRTY="true"

  # command execution time stamp shown in the history
  export HIST_STAMPS="mm/dd/yyyy"

  # https://github.com/robbyrussell/oh-my-zsh/wiki/Plugins
  plugins=(
    git
    common-aliases
    extract
    # zsh-syntax-highlighting
  )

  if is_linux; then
    plugins+=(command-not-found)
  fi
}

configure_oh_my_zsh
source "$ZSH/oh-my-zsh.sh"
