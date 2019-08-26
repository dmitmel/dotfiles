#!/usr/bin/env zsh

source "$ZSH_DOTFILES/zplg.zsh"

plugin completions 'zsh-users/zsh-completions'

run_compinit() {
  autoload -U compinit

  local match run_compdump=1
  # glob qualifiers description:
  #   N    turn on NULL_GLOB for this expansion
  #   .    match only plain files
  #   m-1  check if the file was modified today
  # see "Filename Generation" in zshexpn(1)
  for match in $HOME/.zcompdump(N.m-1); do
    run_compdump=
    break
  done

  if [[ -n "$run_compdump" ]]; then
    # -D flag turns off compdump loading
    compinit -D
    compdump
  else
    # -C flag disables some checks performed by compinit - they are not needed
    # because we already have a fresh compdump
    compinit -C
  fi
}
run_compinit

# Oh-My-Zsh {{{

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

plugin fzf 'junegunn/fzf' build='./install --bin' \
  after_load='plugin-cfg-path path prepend bin' \
  after_load='plugin-cfg-path manpath prepend man'

plugin alias-tips 'djui/alias-tips'

plugin ssh 'zpm-zsh/ssh'

plugin base16-shell 'chriskempson/base16-shell' \
  after_load='export BASE16_SHELL="$plugin_dir"'

FAST_WORK_DIR="$ZSH_CACHE_DIR"
plugin fast-syntax-highlighting 'zdharma/fast-syntax-highlighting'
