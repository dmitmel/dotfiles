#!/usr/bin/env zsh

configure_syntax_highlighting() {
  source "$DOTFILES_PATH/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh"
}

configure_dircolors() {
  [[ -f ~/.dircolors ]] && eval "$(dircolors ~/.dircolors)"
  [[ -z "$LS_COLORS" ]] && eval "$(dircolors -b)"

  zstyle ':completion:*' list-colors "${(@s.:.)LS_COLORS}"
}

configure_syntax_highlighting
configure_dircolors
