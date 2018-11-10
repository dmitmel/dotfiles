#!/usr/bin/env zsh

configure_oh_my_zsh() {
  # use hyphen-insensitive completion (makes `_` and `-` interchangeable)
  HYPHEN_INSENSITIVE="true"

  # enable command auto-correction
  ENABLE_CORRECTION="true"

  # display red dots while waiting for completion
  COMPLETION_WAITING_DOTS="true"

  # disable marking untracked files under VCS as dirty (this makes repository
  # status check for large repositories faster)
  DISABLE_UNTRACKED_FILES_DIRTY="true"

  # command execution time stamp shown in the history
  HIST_STAMPS="mm/dd/yyyy"
}

configure_syntax_highlighting() {
  FAST_WORK_DIR="$DOTFILES_PATH/cache"
}

configure_oh_my_zsh
configure_syntax_highlighting

source "$DOTFILES_PATH/zgen/zgen.zsh"

if ! zgen saved; then
  zgen oh-my-zsh

  zgen oh-my-zsh plugins/git
  zgen oh-my-zsh plugins/common-aliases
  zgen oh-my-zsh plugins/extract
  zgen oh-my-zsh plugins/fasd
  is_linux && zgen oh-my-zsh plugins/command-not-found

  zgen load zdharma/fast-syntax-highlighting

  zgen oh-my-zsh themes/agnoster

  zgen save
fi
