#!/usr/bin/env zsh

export LANG="en_US.UTF-8"
export LC_ALL="$LANG"

if [[ -z "$USER" && -n "$USERNAME" ]]; then
  export USER="$USERNAME"
fi

# find editor
export EDITOR="nvim"
export VISUAL="$EDITOR"
alias edit="$EDITOR"
alias e="$EDITOR"

export CLICOLOR="1"
