#!/usr/bin/env zsh

if command_exists fzf; then
  # taken from https://github.com/junegunn/fzf/blob/master/shell/key-bindings.zsh
  fzf-history-widget() {
    setopt localoptions pipefail
    local selected
    selected=(
      $(fc -rl 1 |
        fzf --height=40% --reverse --nth=2.. --tiebreak=index --query="$LBUFFER")
    )
    local fzf_ret="$?"
    if (( ${#selected} )); then
      zle vi-fetch-history -n "${selected[1]}"
    fi
    zle reset-prompt
    return "$fzf_ret"
  }

  zle     -N    fzf-history-widget
  bindkey '^[r' fzf-history-widget
fi
