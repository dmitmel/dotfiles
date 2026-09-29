# Tie these env variables to zsh arrays (in addition to $path/$PATH and
# $manpath/$MANPATH, which zsh ties together out of the box)
export -T PKG_CONFIG_PATH pkg_config_path ':'
export -T LD_LIBRARY_PATH ld_library_path ':'

# Usually $MANPATH will be absent from the environment zsh was started with, so
# any changes made to it or its array counterpart won't be automatically
# exported by zsh either. Let's ensure that it always appears in the env.
export MANPATH PATH
# Also, it should contain an empty string entry -- a stand-in for the default
# (system) search path; in other words, $MANPATH has to either start with a
# colon, end with a colon, or contain a `::` in the middle (see manpath(5)).
if (( ${#manpath[@]} == 0 || ${#MANPATH} == 0 )) || ! contains manpath ''; then
  manpath+=('')
fi

path_prepend() {
  local var_name="${1:?a variable name is needed}"; shift 1
  local value; for value in "$@"; do
    if ! contains "$var_name" "$value"; then
      set -A "$var_name" "$value" "${(@P)var_name}"
    fi
  done
}

path_append() {
  local var_name="${1:?a variable name is needed}"; shift 1
  local value; for value in "$@"; do
    if ! contains "$var_name" "$value"; then
      set -A "$var_name" "${(@P)var_name}" "$value"
    fi
  done
}

# Glob qualifiers used in this script:
#
# `N` = enables the option NULL_GLOB for a single pattern (in other words,
# disables the error when the pattern didn't match anything)
# `-` = toggles dereferencing symlinks before checking the type of the file on
# and off (which is off by default: symlinks are not resolved and are treated as
# their own file type; we need it on)
# `/` = matches only directories
#
# Actually, we can put these modifiers after an individual path to make it into
# a glob that will expand to nothing if that path does not exist or is of a
# wrong type, which is a nice and helpful shorthand.

if [[ "$OSTYPE" == 'darwin'* ]]; then
  if ! is_defined HOMEBREW_PREFIX; then
    # <https://github.com/Homebrew/brew/blob/7.0.7/Library/Homebrew/utils/os.sh#L10-L51>
    if [[ "$CPUTYPE" == 'arm64' || "$CPUTYPE" == 'aarch64' ]]; then
      local HOMEBREW_PREFIX='/opt/homebrew'
    else
      local HOMEBREW_PREFIX='/usr/local'
    fi
  fi

  # GNU counterparts of command line utilities
  path_prepend path "$HOMEBREW_PREFIX"/opt/*/libexec/gnubin(N-/)
  path_prepend manpath "$HOMEBREW_PREFIX"/opt/*/libexec/gnuman(N-/)

  # add some keg-only Homebrew formulas
  local formula_dir
  for formula_dir in "$HOMEBREW_PREFIX"/opt/(curl|file-formula|openssl|ruby)(N-/); do
    path_prepend path "$formula_dir"/bin(N-/)
    path_prepend pkg_config_path "$formula_dir"/lib/pkgconfig(N-/)
  done

  # Use Python 3 executables by default, i.e. when a version suffix (`python3`)
  # is not specified.
  path_prepend path "$HOMEBREW_PREFIX"/opt/python@3/libexec/bin(N-/)

  # Python packages (for some reason they don't go into ~/.local/bin, but
  # instead into the garbage ~/Library directory)
  path_prepend path ~/Library/Python/*/bin(N-/)
fi

# Ruby gems
path_prepend path ~/.gem/ruby/*/bin(N-/)
path_prepend path ~/.local/share/gem/ruby/*/bin(N-/)

# Yarn global packages
path_prepend path ~/.yarn/bin(N-/)

# <https://go.dev/wiki/GOPATH>
# <https://www.reddit.com/r/golang/comments/10psufn/avoid_having_a_go_directory/>
export GOPATH="${XDG_CACHE_HOME:-$HOME/.cache}/go"
export GOBIN="${HOME}/.local/bin"
path_prepend path "${GOBIN:-$GOPATH/bin}"(N-/)

# Rust
local rustup_home="${RUSTUP_HOME:-$HOME/.rustup}"
if [[ -f "$rustup_home"/settings.toml ]]; then
  # Make a low-effort attempt at quickly extracting the selected Rust toolchain
  # from rustup's settings. The TOML file is obviously assumed to be well-formed
  # and syntactically correct because virtually always it's manipulated with the
  # use of rustup's CLI. Also a shortcut is taken: strings aren't unescaped
  # because Rust toolchain names don't need escaping in strings.
  # See also <https://github.com/toml-lang/toml/blob/master/toml.abnf> and
  # <https://github.com/rust-lang/rustup/blob/66b5ff87b793d0abadc7e2a10298c3a076cc89f4/doc/user-guide/src/concepts/toolchains.md>.
  local default_toolchain='' line=''
  < "$rustup_home"/settings.toml while IFS= read -r line; do
    if [[ "$line" =~ '^default_toolchain = "([a-zA-Z0-9._-]+)"$' ]]; then
      default_toolchain="${match[1]}"
      break
    elif [[ "$line" == \[*\] ]]; then
      break
    fi
  done

  if [[ -n "$default_toolchain" ]]; then
    local rust_sysroot="$rustup_home"/toolchains/"$default_toolchain"
    # path_append path "$rust_sysroot"/bin(N-/)
    # path_prepend fpath "$rust_sysroot"/zsh/site-functions(N-/)
    path_prepend manpath "$rust_sysroot"/share/man(N-/)
  fi

  # The file names of all libraries in the toolchain directories are suffixed
  # with their build hashes or the compiler revision, thus soname conflicts
  # should not be possible.
  path_prepend ld_library_path "$rustup_home"/toolchains/*/lib(N-/)
fi

path_prepend path ~/.cargo/bin(N-/)

path_prepend path "${ZSH_DOTFILES:h}/scripts"
path_prepend path ~/.local/bin(N-/)
