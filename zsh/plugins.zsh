#!/usr/bin/env zsh

plugin completions 'zsh-users/zsh-completions'

# Oh My Zsh {{{

  omz_features=(key-bindings termsupport)
  omz_plugins=(git)

  if ! is_function command_not_found_handler; then
    omz_plugins+=(command-not-found)
  fi

  plugin ohmyzsh 'ohmyzsh/ohmyzsh' \
    load='lib/'${^omz_features}'.zsh' \
    load='plugins/'${^omz_plugins}'/*.plugin.zsh' \
    before_load='ZSH="$plugin_dir"' \
    before_load='plugin-cfg-path fpath prepend plugins/'${^omz_plugins} \
    after_load='plugin-cfg-path fpath prepend plugins/rust' # completion script for `rustc`

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
    rm -f "$match"
  done; unset match

  plugin zsh-z 'agkozak/zsh-z' build='zcompile -R zsh-z.plugin.zsh'

# }}}

if [[ -n "${DOTFILES_INSTALL_FZF}" ]]; then
  plugin fzf 'junegunn/fzf' \
    build='plugin-cfg-git-checkout-version "*"' \
    build='./install --bin' \
    after_load='plugin-cfg-path path prepend bin' \
    after_load='plugin-cfg-path manpath prepend man'
fi

FAST_WORK_DIR="$ZSH_CACHE_DIR"
if [[ "$TERM" != "linux" ]]; then
  # `*.ch` files are compiled in an extra step because Zsh is unable to write
  # the compiled `zwc` files without `cd`ing into the `→chroma` directory first.
  # Unicode problems in 2025, yay!
  plugin fast-syntax-highlighting 'zdharma-continuum/fast-syntax-highlighting' \
    build='(for f in fast* .fast* **/*.zsh; zcompile -R -- "$f")' \
    build='(cd -- →chroma; for f in *.ch; zcompile -R -- "$f")'

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
