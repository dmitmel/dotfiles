#!/usr/bin/env zsh

export LANG="en_US.UTF-8"
export LC_ALL="$LANG"

if [[ -z "$USER" && -n "$USERNAME" ]]; then
  export USER="$USERNAME"
fi

if [[ -n "$SSH_CONNECTION" ]]; then
  export EDITOR="rmate"
else
  export EDITOR="code --wait"
fi

export CLICOLOR="1"

