#!/usr/bin/env zsh

export USER="${USER:-$USERNAME}"

# find editor
export EDITOR="nvim"
export VISUAL="$EDITOR"
alias edit="$EDITOR"
alias e="$EDITOR"

export CLICOLOR=1

READNULLCMD=cat

if [[ -z "$LS_COLORS" ]] && command_exists dircolors; then
  eval "$(dircolors --bourne-shell)"
fi
