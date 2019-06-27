#!/usr/bin/env zsh

# https://github.com/zdharma/zplugin/blob/master/doc/mod-install.sh
# https://github.com/zdharma/zplugin/blob/master/zmodules/Src/Makefile.in
# https://github.com/zsh-users/zsh/blob/master/Etc/zsh-development-guide

source "$ZSH_DOTFILES/zplg.zsh"

plugin completions 'zsh-users/zsh-completions'

# Oh-My-Zsh {{{

  # initialize the completion system
  autoload -Uz compinit && compinit -C

  ZSH_CACHE_DIR="$ZSH_DOTFILES/cache"

  # disable automatic updates because OMZ is managed by my plugin manager
  DISABLE_AUTO_UPDATE=true

  # use hyphen-insensitive completion (makes `_` and `-` interchangeable)
  HYPHEN_INSENSITIVE=true

  # enable command auto-correction
  ENABLE_CORRECTION=true

  # display red dots while waiting for completion
  COMPLETION_WAITING_DOTS=true

  # disable marking untracked files under VCS as dirty (this makes repository
  # status check for large repositories much faster)
  DISABLE_UNTRACKED_FILES_DIRTY=true

  # command execution time stamp shown in the history
  HIST_STAMPS=dd.mm.yyyy

  omz_plugins=(git extract fasd)

  plugin oh-my-zsh 'robbyrussell/oh-my-zsh' \
    load='lib/*.zsh' load='plugins/'${^omz_plugins}'/*.plugin.zsh' \
    ignore='lib/(compfix|diagnostics).zsh' \
    before_load='ZSH="$plugin_dir"' \
    after_load='plugin-cfg-path fpath prepend completions functions' \
    after_load='plugin-cfg-path fpath prepend plugins/'${^omz_plugins}

  unset omz_plugins

# }}}

# spaceship prompt {{{

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

  plugin spaceship-prompt 'denysdovhan/spaceship-prompt'

# }}}

plugin fzf 'junegunn/fzf' build='./install --bin' \
  after_load='plugin-cfg-path path prepend bin' \
  after_load='plugin-cfg-path manpath prepend man'

plugin alias-tips 'djui/alias-tips'

plugin ssh 'zpm-zsh/ssh'

plugin base16-shell 'chriskempson/base16-shell' \
  after_load='export BASE16_SHELL="$plugin_dir"'

autoload -Uz compinit && compinit -C

FAST_WORK_DIR="$ZSH_CACHE_DIR"
plugin fast-syntax-highlighting 'zdharma/fast-syntax-highlighting'
