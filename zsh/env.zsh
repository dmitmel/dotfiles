#!/usr/bin/env zsh

# find editor
export EDITOR="nvim"
export VISUAL="$EDITOR"
alias edit="$EDITOR"
alias e="$EDITOR"

export PAGER='less'
export LESS='--RAW-CONTROL-CHARS'

export CLICOLOR=1

# BSD ls colors
export LSCOLORS="Gxfxcxdxbxegedabagacad"
# GNU ls colors
if [[ -z "$LS_COLORS" ]] && command_exists dircolors; then
  eval "$(dircolors --bourne-shell)"
fi
