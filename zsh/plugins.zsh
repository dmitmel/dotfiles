#!/usr/bin/env zsh

configure_oh_my_zsh() {
  # disable automatic updates because OMZ is managed by zgen
  DISABLE_AUTO_UPDATE="true"

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
  FAST_WORK_DIR="$ZSH_DOTFILES/cache"
}

configure_prompt() {
  SPACESHIP_PROMPT_ADD_NEWLINE=false

  SPACESHIP_PROMPT_ORDER=(
    user
    host
    dir
    git
    # hg
    exec_time
    # vi_mode
    jobs
    exit_code
    line_sep
    char
  )

  SPACESHIP_CHAR_SYMBOL="$ "
  SPACESHIP_CHAR_SYMBOL_ROOT="# "
  SPACESHIP_CHAR_SYMBOL_SECONDARY="> "
  SPACESHIP_GIT_STATUS_DELETED="\u2718 "
  SPACESHIP_HG_STATUS_DELETED="\u2718 "
  SPACESHIP_EXIT_CODE_SYMBOL="\u2718 "
  SPACESHIP_JOBS_SYMBOL="\u2726 "

  SPACESHIP_USER_SHOW=always

  SPACESHIP_DIR_TRUNC=0
  SPACESHIP_DIR_TRUNC_REPO=false

  SPACESHIP_EXIT_CODE_SHOW=true
}

configure_oh_my_zsh
configure_syntax_highlighting
configure_prompt

source "$ZSH_DOTFILES/zgen/zgen.zsh"

if ! zgen saved; then
  zgen oh-my-zsh

  zgen oh-my-zsh plugins/git
  zgen oh-my-zsh plugins/extract
  zgen oh-my-zsh plugins/fasd
  is_linux && zgen oh-my-zsh plugins/command-not-found

  zgen load zdharma/fast-syntax-highlighting

  zgen load denysdovhan/spaceship-prompt spaceship

  zgen load chriskempson/base16-shell

  zgen save
fi
