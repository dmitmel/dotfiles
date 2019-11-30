#!/usr/bin/env zsh

# tie these env variables to zsh arrays
typeset -T PKG_CONFIG_PATH pkg_config_path ':'

# keep only unique values in these arrays
typeset -U path fpath manpath pkg_config_path
export  -U PATH FPATH MANPATH PKG_CONFIG_PATH

path_append() {
  local arr_name="$1" value="$2"
  if eval "if (( \${${arr_name}[(ie)\$value]} > \${#${arr_name}} ))"; then
    eval "${arr_name}+=(\"\$value\")"
    eval "${arr_name}=(\"\${${arr_name}[@]}\" \"\$value\")"
  fi
}

path_prepend() {
  local arr_name="$1" value="$2"
  if eval "if (( \${${arr_name}[(ie)\$value]} > \${#${arr_name}} ))"; then
    eval "${arr_name}=(\"\$value\" \"\${${arr_name}[@]}\")"
  fi
}

if is_macos; then
  path=(
    ~/Library/Python/*/bin
    /usr/local/opt/ruby/bin
    /usr/local/opt/file-formula/bin         # file
    /usr/local/opt/gnu-tar/libexec/gnubin   # GNU tar
    /usr/local/opt/unzip/bin                # GNU unzip
    /usr/local/opt/openssl/bin              # openssl
    /usr/local/opt/gnu-getopt/bin           # getopt
    /usr/local/opt/findutils/libexec/gnubin # GNU findutils
    /usr/local/opt/coreutils/libexec/gnubin # GNU coreutils
    /usr/local/opt/curl/bin                 # curl
    "${path[@]}"
  )

  manpath=(
    /usr/local/opt/findutils/libexec/gnuman # GNU findutils
    "${manpath[@]}"
  )

  for formula in ruby openssl curl; do
    formula_path="/usr/local/opt/$formula"
    if [[ -d "$formula_path" ]]; then
      pkg_config_path+=( "$formula_path"/lib/pkgconfig )
    fi
  done
fi

# Yarn global packages
path=(~/.yarn/bin "${path[@]}")

# Go
export GOPATH=~/.go
path=("$GOPATH/bin" "${path[@]}")

# Rust
path=(~/.cargo/bin "${path[@]}")
# check if the Rust toolchain was installed via rustup
if rustup_home="$(rustup show home 2> /dev/null)" &&
   rust_sysroot="$(rustc --print sysroot 2> /dev/null)" &&
  [[ -d "$rustup_home" && -d "$rust_sysroot" && "$rust_sysroot" == "$rustup_home"/* ]]
then
  # add paths of the selected Rust toolchain
  fpath=("$rust_sysroot/share/zsh/site-functions" "${fpath[@]}")
  manpath=("$rust_sysroot/share/man" "${manpath[@]}")
fi
unset rustup_home rust_sysroot

# add my binaries and completions
path=("${ZSH_DOTFILES:h}/scripts" "${path[@]}")
fpath=("$ZSH_DOTFILES/completions" "${fpath[@]}")

# add user binaries
path=(~/.local/bin "${path[@]}")
