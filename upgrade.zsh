#!/usr/bin/env zsh

DOTFILES_PATH="${0:a:h}"
cd "$DOTFILES_PATH" || exit 1
ZSH_DOTFILES="$DOTFILES_PATH/zsh"

git pull --rebase --stat origin master
git submodule update --init --recursive --remote --progress

source "$ZSH_DOTFILES/plugins.zsh"
zplg-upgrade
