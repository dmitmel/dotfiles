#!/usr/bin/env bash

set -e

cd "$(dirname "${BASH_SOURCE[0]}")"

mkdir -p out

declare -A apps=(
  [iterm]=itermcolors
  [kitty]=conf
  [nvim]=vim
  [setvtrgb]=txt
  [shell]=zsh
  [termux]=properties
)

for app in "${!apps[@]}"; do
  output_file="$app.${apps[$app]}"
  echo "$output_file"
  ./"$app".py > ./out/"$output_file"
done
