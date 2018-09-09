#!/usr/bin/env zsh

arr_push() { eval "export $1=\"$2:\$$1\""; }

# user binaries
arr_push PATH "$HOME/bin"
arr_push PATH "$HOME/.local/bin"
# Rust binaries
arr_push PATH "$HOME/.cargo/bin"
# global Yarn packages
arr_push PATH "$HOME/.config/yarn/global/node_modules/.bin"

if is_macos; then
  # Haskell packages
  arr_push PATH "$HOME/Library/Haskell/bin"

  # GNU sed
  arr_push PATH    "/usr/local/opt/gnu-tar/libexec/gnubin"
  arr_push MANPATH "/usr/local/opt/gnu-tar/libexec/gnuman"
  # GNU tar
  arr_push PATH    "/usr/local/opt/gnu-sed/libexec/gnubin"
  arr_push MANPATH "/usr/local/opt/gnu-sed/libexec/gnuman"
  # GNU coreutils
  arr_push PATH    "/usr/local/opt/coreutils/libexec/gnubin"
  arr_push MANPATH "/usr/local/opt/coreutils/libexec/gnuman"
fi

arr_push FPATH "$DOTFILES_PATH/completions"
command_exists rustc && arr_push FPATH "$(rustc --print sysroot)/share/zsh/site-functions"

unset arr_push
