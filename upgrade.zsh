#!/usr/bin/env zsh

DOTFILES_PATH="${0:a:h}"
cd "$DOTFILES_PATH" || exit 1
ZSH_DOTFILES="$DOTFILES_PATH/zsh"

source "$ZSH_DOTFILES/functions.zsh"

git pull --rebase --stat origin master
git submodule update --init --recursive --remote --progress

ZPLG_SKIP_LOADING=1
source "$ZSH_DOTFILES/plugins.zsh"
zplg-upgrade
