#!/usr/bin/env zsh

mkdir -pv "$ZSH_CACHE_DIR"

_plugin() {
  _perf_timer_start "plugin $1"
  plugin "$@"
  _perf_timer_stop "plugin $1"
}

_checkout_latest_version='build=plugin-cfg-git-checkout-version "*"'

_plugin completions 'zsh-users/zsh-completions' "$_checkout_latest_version"

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
  for match in "${ZSH_CACHE_DIR}/zcompdump"(N.m-1); do
    run_compdump=0
    break
  done; unset match

  if (( $run_compdump )); then
    print -r -- "$0: rebuilding zsh completion dump"
    # -D flag turns off compdump loading
    compinit -D -d "${ZSH_CACHE_DIR}/zcompdump"
    compdump
  else
    # -C flag disables some checks performed by compinit - they are not needed
    # because we already have a fresh compdump
    compinit -C -d "${ZSH_CACHE_DIR}/zcompdump"
  fi
  unset run_compdump
# }}}

# Oh My Zsh {{{

  omz_features=(key-bindings termsupport)
  omz_plugins=(git)

  _plugin ohmyzsh 'ohmyzsh/ohmyzsh' \
    load='lib/'${^omz_features}'.zsh' \
    load='plugins/'${^omz_plugins}'/*.plugin.zsh' \
    before_load='ZSH="$plugin_dir"' \
    after_load='plugin-cfg-path fpath prepend completions functions' \
    after_load='plugin-cfg-path fpath prepend plugins/'${^omz_plugins}

  unset omz_plugins

# }}}

# fasd {{{

  if ! command_exists fasd; then
    _plugin fasd 'clvv/fasd' \
      build='mkdir -pv man1 && cp -v ./fasd.1 man1/'
      after_load='plugin-cfg-path path prepend ""' \
      after_load='plugin-cfg-path manpath prepend ""'
  fi

  if command_exists fasd; then
    export _FASD_DATA="${XDG_DATA_HOME:-$HOME/.local/share}/fasd_db.csv"

    # Initialization taken from <https://github.com/ohmyzsh/ohmyzsh/blob/6fbad5bf72fad4ecf30ba4d4ffee62bac582f0ed/plugins/fasd/fasd.plugin.zsh>
    fasd_cache="${ZSH_CACHE_DIR}/fasd-init-cache"
    if [[ "${commands[fasd]}" -nt "$fasd_cache" || ! -s "$fasd_cache" ]]; then
      fasd --init posix-alias zsh-hook zsh-ccomp zsh-ccomp-install zsh-wcomp zsh-wcomp-install >| "$fasd_cache"
    fi
    source "$fasd_cache"
    unset fasd_cache

    alias v='f -e "$EDITOR"'
    alias o='a -e xdg-open'

    # alias j='zz'
    j() {
      local _fasd_ret
      _fasd_ret="$(
        # -l: list all paths in the database (without scores)
        # -d: list only directories
        # -R: in the reverse order
        fasd -l -d -R |
          fzf --height=40% --layout=reverse --tiebreak=index --query="$*"
      )"
      if [[ -d "$_fasd_ret" ]]; then
        cd -- "$_fasd_ret"
      elif [[ -n "$_fasd_ret" ]]; then
        print -r -- "$_fasd_ret"
      fi
    }
  fi

# }}}

# _plugin fzf 'junegunn/fzf' "$_checkout_latest_version" \
#   build='./install --bin' \
#   after_load='plugin-cfg-path path prepend bin' \
#   after_load='plugin-cfg-path manpath prepend man'

if command_exists python; then
  _plugin alias-tips 'djui/alias-tips'
fi

FAST_WORK_DIR="$ZSH_CACHE_DIR"
if [[ "$TERM" != "linux" ]]; then
  _plugin fast-syntax-highlighting 'zdharma/fast-syntax-highlighting' "$_checkout_latest_version"
  set-my-syntax-theme() { fast-theme "$ZSH_DOTFILES/my-syntax-theme.ini" "$@"; }
  if [[ "$FAST_THEME_NAME" != "my-syntax-theme" && -z "$DOTFILES_DISABLE_MY_SYNTAX_THEME" ]]; then
    set-my-syntax-theme
  fi
fi

unset _checkout_latest_version
