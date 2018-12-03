#!/usr/bin/env zsh

DOTFILES_PATH="${0:h}"
cd "$DOTFILES_PATH" || exit 1

git pull --rebase --stat origin master
git submodule update --init --recursive --remote

source "./zgen/zgen.zsh"
zgen update
