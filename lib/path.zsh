#!/usr/bin/env zsh

prepend() { eval "export $1=\"$2:\$$1\""; }
append()  { eval "export $1=\"\$$1:$2\""; }

# user binaries
append PATH "$HOME/bin"
append PATH "$HOME/.local/bin"
# Rust binaries
prepend PATH "$HOME/.cargo/bin:$PATH"
# global Yarn packages
append PATH "$HOME/.config/yarn/global/node_modules/.bin"

if is_macos; then
  # GNU sed
  prepend PATH    "/usr/local/opt/gnu-tar/libexec/gnubin"
  prepend MANPATH "/usr/local/opt/gnu-tar/libexec/gnuman"
  # GNU tar
  prepend PATH    "/usr/local/opt/gnu-sed/libexec/gnubin"
  prepend MANPATH "/usr/local/opt/gnu-sed/libexec/gnuman"
  # GNU coreutils
  prepend PATH    "/usr/local/opt/coreutils/libexec/gnubin"
  prepend MANPATH "/usr/local/opt/coreutils/libexec/gnuman"
  # Haskell packages
  append PATH "$HOME/Library/Haskell/bin"
fi

