#!/usr/bin/env zsh

# make these variables unique (-U) arrays (-a)
typeset -aU fpath manpath path

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
    "${path[@]}"
  )

  manpath=(
    /usr/local/opt/ruby/share/man
    /usr/local/opt/file-formula/share/man   # file
    /usr/local/opt/gnu-tar/libexec/gnuman   # GNU tar
    /usr/local/opt/unzip/share/man          # GNU unzip
    /usr/local/opt/openssl/share/man        # openssl
    /usr/local/opt/gnu-getopt/share/man     # getopt
    /usr/local/opt/findutils/libexec/gnuman # GNU findutils
    /usr/local/opt/coreutils/libexec/gnuman # GNU coreutils
    "${manpath[@]}"
  )
fi

# add Go binaries
export GOPATH="$HOME/.go"
path=("$GOPATH/bin" "${path[@]}")

# add user binaries
path=(~/bin ~/.local/bin "${path[@]}")

# add my completions
fpath=("$DOTFILES_PATH/completions" "${fpath[@]}")

# check for Rust installed via rustup
if rust_sysroot="$(~/.cargo/bin/rustc --print sysroot 2> /dev/null)"; then
  # add paths of the current Rust toolchain
  path=(~/.cargo/bin "${path[@]}")
  fpath=("$rust_sysroot/share/zsh/site-functions" "${fpath[@]}")
  manpath=("$rust_sysroot/share/man" "${manpath[@]}")
fi
unset rust_sysroot

# add colon after MANPATH so that it doesn't overwrite system MANPATH
MANPATH="$MANPATH:"

export PATH MANPATH
