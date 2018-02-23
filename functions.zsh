#!/usr/bin/env bash

is_linux() {
  [[ $OSTYPE == linux* ]]
}

is_macos() {
  [[ $OSTYPE == darwin* ]]
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

source_if_exists() {
  [[ -f $1 ]] && source "$1"
}
