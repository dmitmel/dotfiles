#!/usr/bin/env zsh

export PATH
export MANPATH

# tie these env variables to zsh arrays
export -T PKG_CONFIG_PATH pkg_config_path ':'
export -T LD_LIBRARY_PATH ld_library_path ':'

path_prepend() {
  if (( $# < 1 )); then
    print >&2 -r -- "usage: $0 <var_name> <value...>"
    return 1
  fi
  local var_name="$1"; shift
  local value; for value in "$@"; do
  if (( ${${(P)var_name}[(ie)$value]-1} > ${#${(P)var_name}} )); then
      set -A "$var_name" "$value" "${(@P)var_name}"
    fi
  done
}

# glob modifiers used in this script:
#
# N - enables the null_glob option for a single glob pattern, in other words
# ignores an error when the pattern didn't match anything
#
# / - matches only directories

if [[ "$OSTYPE" == darwin* ]]; then
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

  # Python packages (for some reason they don't go into ~/.local/bin, but
  # instead into the garbage ~/Library directory)
  path_prepend path ~/Library/Python/*/bin(N/)
fi

# Ruby gems
path_prepend path ~/.gem/ruby/*/bin(N/)
path_prepend path ~/.local/share/gem/ruby/*/bin(N/)

# Yarn global packages
path_prepend path ~/.yarn/bin

# Go
export GOPATH=~/go
path_prepend path "$GOPATH/bin"

# Rust
rustup_home="${RUSTUP_HOME:-$HOME/.rustup}"
if [[ -f "$rustup_home"/settings.toml ]]; then
  # Make a low-effort attempt at quickly extracting the selected Rust toolchain
  # from rustup's settings. The TOML file is obviously assumed to be well-formed
  # and syntactically correct because virtually always it's manipulated with the
  # use of rustup's CLI. Also a shortcut is taken: strings aren't unescaped
  # because Rust toolchain names don't need escaping in strings.
  # See also <https://github.com/toml-lang/toml/blob/master/toml.abnf>.
  rust_toolchain=""
  < "$rustup_home"/settings.toml while IFS= read -r line; do
    if [[ "$line" =~ '^default_toolchain = "(.+)"$' ]]; then
      rust_toolchain="${match[1]}"
      break
    elif [[ "$line" == \[*\] ]]; then
      break
    fi
  done; unset line

  if [[ -n "$rust_toolchain" ]]; then
    rust_sysroot="$rustup_home"/toolchains/"$rust_toolchain"
    # path_append path "$rust_sysroot"/bin
    # path_prepend fpath "$rust_sysroot"/zsh/site-functions
    path_prepend manpath "$rust_sysroot"/share/man
  fi

  for rust_sysroot in "$rustup_home"/toolchains/*(/); do
    # The filenames of all libraries in toolchain dirs are suffixed with their
    # build hashes or the compiler identifier, so in practice conflicts are
    # insanely unlikely.
    path_prepend ld_library_path "$rust_sysroot"/lib
  done
fi
unset rustup_home rust_toolchain rust_sysroot

path_prepend path ~/.cargo/bin

path_prepend path "${ZSH_DOTFILES:h}/scripts"
path_prepend path ~/.local/bin

unfunction path_prepend

# For some reason manpath is not always set when logging with ssh for instance.
# Let's ensure that it is always set and exported. The additional colon ensures
# that the system manpath isn't overwritten (see manpath(1)).
if [[ -n "$MANPATH" && "$MANPATH" != *: ]]; then
  # Append a colon if MANPATH isn't empty and doesn't end with a colon already
  MANPATH="$MANPATH:"
fi
export MANPATH="$MANPATH"
