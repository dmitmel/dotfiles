#!/usr/bin/env zsh

# find editor
export EDITOR="nvim"
export VISUAL="$EDITOR"

export PAGER='less'
export LESS='--RAW-CONTROL-CHARS'

export CLICOLOR=1

# BSD ls colors
export LSCOLORS="Gxfxcxdxbxegedabagacad"
# GNU ls colors
if [[ -z "$LS_COLORS" ]] && command_exists dircolors; then
  eval "$(dircolors --bourne-shell)"
fi

# see COLORS in jq(1)
jq_colors=(
  "0;38;5;16" # null
  "0;38;5;16" # false
  "0;38;5;16" # true
  "0;38;5;16" # numbers
  "0;32"      # strings
  "0;39"      # arrays
  "0;39"      # objects
)
# join all values from jq_colors with a colon
export JQ_COLORS="${(j.:.)jq_colors}"
unset jq_colors

export HOMEBREW_NO_AUTO_UPDATE=1
