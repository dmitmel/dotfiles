#!/usr/bin/env zsh

# tie these env variables to zsh arrays
typeset -T LDFLAGS ldflags ' '
typeset -T CPPFLAGS cppflags ' '
typeset -T PKG_CONFIG_PATH pkg_config_path ':'

# keep only unique values in these arrays
typeset -U path fpath manpath ldflags cppflags pkg_config_path
export  -U PATH FPATH MANPATH LDFLAGS CPPFLAGS PKG_CONFIG_PATH

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
      ldflags+=( -L"$formula_path"/lib )
      cppflags+=( -L"$formula_path"/include )
      pkg_config_path+=( "$formula_path"/lib/pkgconfig )
    fi
  done
fi

# add Go binaries
export GOPATH="$HOME/.go"
path=("$GOPATH/bin" "${path[@]}")

# add user binaries
path=(~/.local/bin "${path[@]}")

# add my binaries and completions
path=("$ZSH_DOTFILES/bin" "${path[@]}")
fpath=("$ZSH_DOTFILES/completions" "${fpath[@]}")

# check for Rust installed via rustup
rustc=~/.cargo/bin/rustc
if [[ -f "$rustc" && -x "$rustc" ]] && rust_sysroot="$("$rustc" --print sysroot)"; then
  # add paths of the default Rust toolchain
  path=(~/.cargo/bin "${path[@]}")
  fpath=("$rust_sysroot/share/zsh/site-functions" "${fpath[@]}")
  manpath=("$rust_sysroot/share/man" "${manpath[@]}")
fi
unset rustc rust_sysroot
