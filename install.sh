#!/usr/bin/env bash

for script in {zhsrc,zlogin}.zsh; do
  ln -sv "$script" ".$script"
done
