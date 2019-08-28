#!/usr/bin/env zsh

is_linux() {
  [[ "$OSTYPE" == linux* ]]
}

is_macos() {
  [[ "$OSTYPE" == darwin* ]]
}

is_android() {
  [[ "$OSTYPE" == linux-android ]]
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

source_if_exists() {
  [[ -f "$1" ]] && source "$1"
}

lazy_load() {
  local command="$1"
  local init_command="$2"

  eval "$command() {
    unfunction $command
    $init_command
    $command \$@
  }"
}

welcome() {
  python "$ZSH_DOTFILES/welcome/main.py"
}

if is_android; then
  alias open='termux-open'
elif is_linux && command_exists xdg-open; then
  open() { nohup xdg-open "$@" &> /dev/null; }
fi
