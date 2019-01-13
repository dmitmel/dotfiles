#!/usr/bin/env zsh

configure_dircolors() {
  [[ -f ~/.dircolors ]] && eval "$(dircolors ~/.dircolors)"
  [[ -z "$LS_COLORS" ]] && eval "$(dircolors -b)"

  zstyle ':completion:*' list-colors "${(@s.:.)LS_COLORS}"
}

configure_dircolors

# This ugly hack is required only for the agnoster theme which I use. I'm
# probably going to switch to another theme because it is so damn slow
autoload -Uz add-zsh-hook
_patch-prompt() { PROMPT="$PROMPT"$'\n%{%F{247}%}\u03bb>%{%b%f%} '; }
add-zsh-hook precmd _patch-prompt
