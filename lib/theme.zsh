#!/usr/bin/env zsh

configure_syntax_highlighting() {
  # set directory for compiled theme files
  FAST_WORK_DIR="$DOTFILES_PATH/cache"
  source "$DOTFILES_PATH/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
}

configure_dircolors() {
  [[ -f ~/.dircolors ]] && eval "$(dircolors ~/.dircolors)"
  [[ -z "$LS_COLORS" ]] && eval "$(dircolors -b)"

  zstyle ':completion:*' list-colors "${(@s.:.)LS_COLORS}"
}

configure_syntax_highlighting
configure_dircolors
