plugin completions 'zsh-users/zsh-completions' \
  after_load='plugin-cfg-path fpath append src'

# Oh My Zsh {{{

  # define these arrays if they have not been defined already
  typeset -ga omz_features omz_plugins

  omz_features+=(key-bindings)
  omz_plugins+=(git)

  if [[ -z "$KITTY_INSTALLATION_DIR" || " $KITTY_SHELL_INTEGRATION " == *' no-title '* ]]; then
    omz_features+=(termsupport)
  fi

  if ! function_exists command_not_found_handler; then
    omz_plugins+=(command-not-found)
  fi

  plugin ohmyzsh 'ohmyzsh/ohmyzsh' \
    load='lib/'${^omz_features}'.zsh' \
    load='plugins/'${^omz_plugins}'/*.plugin.zsh' \
    before_load='ZSH="$plugin_dir"' \
    before_load='plugin-cfg-path fpath prepend plugins/'${^omz_plugins}

# }}}

# directory jumping {{{
  # <https://github.com/clvv/fasd>
  # <https://github.com/agkozak/zsh-z>
  # <https://github.com/skywind3000/z.lua>
  # <https://github.com/rupa/z>
  # <https://github.com/wting/autojump>
  # <https://github.com/ajeetdsouza/zoxide>

  ZSHZ_CASE=smart
  ZSHZ_DATA="${XDG_DATA_HOME:-$HOME/.local/share}/zshz_db.txt"
  ZSHZ_UNCOMMON=1

  # The plugin sometimes leaves behind the temporary files it creates for
  # atomically updating its database, so we find and delete them ourselves. The
  # glob selects files which were modified older than a week ago.
  for match in "${ZSHZ_DATA}".*(N.mw+1); do
    command rm -f -- "$match"
  done; unset match

  plugin zsh-z 'agkozak/zsh-z' build='zcompile -R zsh-z.plugin.zsh'

# }}}

# The `${var=default}` syntax sets a `$var` to `default` only if it was not
# defined before (but not if it is set to an empty string -- this counts as the
# variable being defined).
if ! command_exists fzf; then : ${DOTFILES_INSTALL_FZF=yes}; fi
if ! command_exists lf;  then : ${DOTFILES_INSTALL_LF=yes};  fi

if [[ -n "$DOTFILES_INSTALL_FZF" ]]; then
  plugin fzf 'junegunn/fzf' \
    build='plugin-cfg-git-checkout-version "*"' \
    build='./install --bin' \
    after_load='plugin-cfg-path path prepend bin' \
    after_load='plugin-cfg-path manpath prepend man'
fi

if [[ -n "$DOTFILES_INSTALL_LF" ]]; then
  () {
    # The naming of lf's build artifacts is based on combinations of $GOOS and $GOARCH.
    # They are documented here: <https://go.dev/doc/install/source#environment>.
    local lf_arch='' lf_os=''

    # The value of $CPUTYPE is derived from the result of the uname(2) syscall.
    # Non-exhaustive lists of its possible values:
    # <https://wiki.debian.org/ArchitectureSpecificsMemo#Summary>
    # <https://en.wikipedia.org/wiki/Uname#Examples>
    case "$CPUTYPE" in
      (x86_64)  lf_arch=amd64 ;;
      (i?86)    lf_arch=386   ;;
      (aarch64) lf_arch=arm64 ;;
      (arm*)    lf_arch=arm   ;;
      (*) return
    esac

    case "$OSTYPE" in
      (linux-android*) lf_os=android ;;
      (linux*)   lf_os=linux   ;;
      (darwin*)  lf_os=darwin  ;;
      (freebsd*) lf_os=freebsd ;;
      (openbsd*) lf_os=openbsd ;;
      (netbsd*)  lf_os=netbsd  ;;
      (*) return
    esac

    local lf_archive_name="lf-${lf_os}-${lf_arch}.tar.gz"
    plugin lf "https://github.com/gokcehan/lf/releases/latest/download/${lf_archive_name}" from=url \
      build='mkdir -p bin && tar -C bin --no-same-owner -xzf "$lf_archive_name" lf && chmod +x bin/lf' \
      build='_zplg_source_url_download \
        "https://raw.githubusercontent.com/gokcehan/lf/refs/tags/$(./bin/lf -version)/lf.1" \
        "${plugin_dir}/man/man1"' \
      after_load='plugin-cfg-path path prepend bin' \
      after_load='plugin-cfg-path manpath prepend man'
  }
fi

# `*.ch` files are compiled in an extra step because Zsh is unable to write
# the compiled `zwc` files without `cd`ing into the `→chroma` directory first.
# Unicode problems in 2025, yay!
# Why `zcompile` is always calledd with `-R`: <https://github.com/romkatv/powerlevel10k/issues/1574#issuecomment-921132158>
plugin fast-syntax-highlighting 'zdharma-continuum/fast-syntax-highlighting' \
  build='for f in (fast*|.fast*)~*.zwc **/*.zsh; zcompile -R -- "$f"' \
  build='cd -- →chroma; for f in *.ch; zcompile -R -- "$f"' \
  before_load='FAST_WORK_DIR="$ZSH_CACHE_DIR"' \
  before_load='plugin-cfg-path fpath prepend .' \
  ${${(M)${DOTFILES_REAL_TERM:-$TERM}:#linux}:+"ignore=*"}  # a shitty ternary operator, adds ignore=* if $TERM == "linux"

if function_exists fast-theme; then
  set-my-syntax-theme() {
    fast-theme "$ZSH_DOTFILES/my-syntax-theme.ini" "$@"
  }
  if [[ "$FAST_THEME_NAME" != "my-syntax-theme" && -z "$DOTFILES_DISABLE_MY_SYNTAX_THEME" ]]; then
    set-my-syntax-theme
  fi
fi

if [[ "$OSTYPE" == darwin* ]]; then
  plugin retina 'https://raw.githubusercontent.com/lunixbochs/meta/master/utils/retina/retina.m' from=url \
    build='mkdir -p bin && gcc retina.m -framework Foundation -framework AppKit -o bin/retina' \
    after_load='plugin-cfg-path path prepend "bin"'
fi
