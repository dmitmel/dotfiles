#!/usr/bin/env zsh

# tie these env variables to zsh arrays
typeset -T PKG_CONFIG_PATH pkg_config_path ':'

export PKG_CONFIG_PATH PATH MANPATH

path_prepend() {
  if (( $# < 1 )); then
    print >&2 "usage: $0 <var_name> <value...>"
    return 1
  fi
  local var_name="$1"; shift
  local value; for value in "$@"; do
    if eval "(( \${${var_name}[(ie)\$value]-1} > \${#${var_name}} ))"; then
      eval "${var_name}=(\"\$value\" \"\${${var_name}[@]}\")"
    fi
  done
}

# glob modifiers used in this script:
#
# N - enables the null_glob option for a single glob pattern, in other words
# ignores an error when the pattern didn't match anything
#
# / - matches only directories

if (( _is_macos )); then
  # GNU counterparts of command line utilities
  path_prepend path /usr/local/opt/*/libexec/gnubin(N/)
  path_prepend manpath /usr/local/opt/*/libexec/gnuman(N/)

  # add some keg-only Homebrew formulas
  for formula in curl file-formula openssl ruby; do
    formula_path="/usr/local/opt/$formula"
    if [[ ! -d "$formula_path" ]]; then
      continue
    fi

    if [[ -d "$formula_path/bin" ]]; then
      path_prepend path "$formula_path/bin"
    fi

    if [[ -d "$formula_path/lib/pkgconfig" ]]; then
      path_prepend pkg_config_path "$formula_path/lib/pkgconfig"
    fi
  done; unset formula

  # Use Python 3 executables by default, i.e. when a version suffix (`python3`)
  # is not specified.
  path_prepend path /usr/local/opt/python@3/libexec/bin
fi

if (( _is_macos )); then
  # Python packages (for some reason they don't go into ~/.local/bin, but
  # instead into the garbage ~/Library directory)
  path_prepend path ~/Library/Python/*/bin(N/)
fi

# Ruby gems
path_prepend path ~/.gem/ruby/*/bin(N/)

# Yarn global packages
path_prepend path ~/.yarn/bin

# Go
export GOPATH=~/go
path_prepend path "$GOPATH/bin"

# Rust
path_prepend path ~/.cargo/bin
# check if the Rust toolchain was installed via rustup
if rustup_home="$(rustup show home 2> /dev/null)" &&
   rust_sysroot="$(rustc --print sysroot 2> /dev/null)" &&
  [[ -d "$rustup_home" && -d "$rust_sysroot" && "$rust_sysroot" == "$rustup_home"/* ]]
then
  # add paths of the selected Rust toolchain
  path_prepend fpath "$rust_sysroot/share/zsh/site-functions"
  path_prepend manpath "$rust_sysroot/share/man"
fi
unset rustup_home rust_sysroot

# add my binaries and completions
path_prepend path "${ZSH_DOTFILES:h}/scripts"
path_prepend fpath "$ZSH_DOTFILES/completions"

# add user binaries
path_prepend path ~/.local/bin

unfunction path_prepend
