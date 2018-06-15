#!/usr/bin/env zsh

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

run_before() {
  local command="$1"
  local init_command="$2"

  eval "$(cat <<EOF
$command() {
  unfunction $command
  $init_command
  $command \$@
}
EOF
)"
}
