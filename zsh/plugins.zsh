#!/usr/bin/env zsh

ZSH_CACHE_DIR="$HOME/.cache/dotfiles"
if [[ ! -d "$ZSH_CACHE_DIR" ]]; then
  mkdir -pv "$ZSH_CACHE_DIR"
fi

source "$ZSH_DOTFILES/zplg.zsh"

_plugin() {
  _perf_timer_start "plugin $1"
  plugin "$@"
  _perf_timer_stop "plugin $1"
}

_plugin completions 'zsh-users/zsh-completions'

# compinit {{{
  # note that completion system must be initialized after zsh-completions and
  # before Oh My Zsh
  autoload -U compinit

  run_compdump=1
  # glob qualifiers description:
  #   N    turn on NULL_GLOB for this expansion
  #   .    match only plain files
  #   m-1  check if the file was modified today
  # see "Filename Generation" in zshexpn(1)
  for match in $HOME/.zcompdump(N.m-1); do
    run_compdump=0
    break
  done; unset match

  if (( $run_compdump )); then
    echo "$0: rebuilding zsh completion dump"
    # -D flag turns off compdump loading
    compinit -D
    compdump
  else
    # -C flag disables some checks performed by compinit - they are not needed
    # because we already have a fresh compdump
    compinit -C
  fi
  unset run_compdump
# }}}

# Oh My Zsh {{{

  omz_features=(key-bindings termsupport)
  omz_plugins=(git extract fasd)

  _plugin ohmyzsh 'ohmyzsh/ohmyzsh' \
    load='lib/'${^omz_features}'.zsh' \
    load='plugins/'${^omz_plugins}'/*.plugin.zsh' \
    before_load='ZSH="$plugin_dir"' \
    after_load='plugin-cfg-path fpath prepend completions functions' \
    after_load='plugin-cfg-path fpath prepend plugins/'${^omz_plugins}

  unset omz_plugins

# }}}

_plugin fzf 'junegunn/fzf' build='./install --bin' \
  after_load='plugin-cfg-path path prepend bin' \
  after_load='plugin-cfg-path manpath prepend man'

_plugin alias-tips 'djui/alias-tips'

FAST_WORK_DIR="$ZSH_CACHE_DIR"
if [[ "$TERM" != "linux" ]]; then
  _plugin fast-syntax-highlighting 'zdharma/fast-syntax-highlighting'
  set-my-syntax-theme() { fast-theme "$ZSH_DOTFILES/my-syntax-theme.ini" "$@"; }
fi
