#!/usr/bin/env zsh

_plugin() {
  _perf_timer_start "plugin $1"
  plugin "$@"
  _perf_timer_stop "plugin $1"
}

_checkout_latest_version='build=plugin-cfg-git-checkout-version "*"'

_plugin completions 'zsh-users/zsh-completions'
_plugin completions-rustc 'https://raw.githubusercontent.com/rust-lang/zsh-config/master/_rust' from=url \
  after_load='plugin-cfg-path fpath prepend ""'
_plugin completions-cargo 'https://raw.githubusercontent.com/rust-lang/cargo/master/src/etc/_cargo' from=url \
  after_load='plugin-cfg-path fpath prepend ""'

if rustup_bin="$(command_locate rustup)" && [[ -n "$rustup_bin" ]]; then
  rustup_comp_path="${ZSH_CACHE_DIR}/site-functions/_rustup"
  if [[ "$rustup_bin" -nt "$rustup_comp_path" || ! -s "$rustup_comp_path" ]]; then
    _perf_timer_start "generate rustup completions"
    "$rustup_bin" completions zsh >| "$rustup_comp_path"
    _perf_timer_stop "generate rustup completions"
  fi
  unset rustup_comp_path
fi; unset rustup_bin

# compinit {{{
  _perf_timer_start "compinit"

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

  # In both branches, -u disables the "security" (see the manpage) check and -d
  # specifies the path to a completion dump.
  if (( $run_compdump )); then
    print -r -- "$0: rebuilding zsh completion dump"
    # -D flag turns off compdump loading
    compinit -u -D -d "${ZSH_CACHE_DIR}/zcompdump"
    compdump
  else
    # -C flag disables some checks performed by compinit - they are not needed
    # because we already have a fresh compdump
    compinit -u -C -d "${ZSH_CACHE_DIR}/zcompdump"
  fi
  unset run_compdump

  _perf_timer_stop "compinit"
# }}}

# Oh My Zsh {{{

  omz_features=(key-bindings termsupport)
  omz_plugins=(git command-not-found)

  _plugin ohmyzsh 'ohmyzsh/ohmyzsh' \
    load='lib/'${^omz_features}'.zsh' \
    load='plugins/'${^omz_plugins}'/*.plugin.zsh' \
    before_load='ZSH="$plugin_dir"' \
    after_load='plugin-cfg-path fpath prepend completions functions' \
    after_load='plugin-cfg-path fpath prepend plugins/'${^omz_plugins}

  unset omz_plugins

# }}}

# directory jumping {{{
  # <https://github.com/clvv/fasd>
  # <https://github.com/agkozak/zsh-z>
  # <https://github.com/skywind3000/z.lua>
  # <https://github.com/rupa/z>
  # <https://github.com/wting/autojump>
  # <https://github.com/ajeetdsouza/zoxide>

  # export _FASD_DATA="${XDG_DATA_HOME:-$HOME/.local/share}/fasd_db.txt"

  ZSHZ_CASE=smart
  ZSHZ_DATA="${XDG_DATA_HOME:-$HOME/.local/share}/zshz_db.txt"
  ZSHZ_UNCOMMON=1

  _plugin zsh-z 'agkozak/zsh-z' \
    after_load='plugin-cfg-path fpath prepend ""'

  j() {
    local _dir
    if _dir="$(
      z -l | sed 's/^[0-9]* *//g' |
      fzf --tac --tiebreak=index --layout=reverse --height=40% --query="$*"
    )"; then
      cd -- "$_dir"
    fi
  }

# }}}

# _plugin fzf 'junegunn/fzf' "$_checkout_latest_version" \
#   build='./install --bin' \
#   after_load='plugin-cfg-path path prepend bin' \
#   after_load='plugin-cfg-path manpath prepend man'

FAST_WORK_DIR="$ZSH_CACHE_DIR"
if [[ "$TERM" != "linux" ]]; then
  _plugin fast-syntax-highlighting 'zdharma-continuum/fast-syntax-highlighting'
  set-my-syntax-theme() { fast-theme "$ZSH_DOTFILES/my-syntax-theme.ini" "$@"; }
  if [[ "$FAST_THEME_NAME" != "my-syntax-theme" && -z "$DOTFILES_DISABLE_MY_SYNTAX_THEME" ]]; then
    set-my-syntax-theme
  fi
fi

if (( _is_macos )); then
  _plugin retina 'https://raw.githubusercontent.com/lunixbochs/meta/master/utils/retina/retina.m' from=url \
    build='mkdir -p bin && gcc retina.m -framework Foundation -framework AppKit -o bin/retina' \
    after_load='plugin-cfg-path path prepend "bin"'
fi

unset _checkout_latest_version
