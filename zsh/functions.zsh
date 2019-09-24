#!/usr/bin/env zsh

count() { echo "$#"; }

mkcd() {
  mkdir -p "$@" && cd "${@[-1]}"
}

is_linux()   { [[ "$OSTYPE" == linux*        ]]; }
is_macos()   { [[ "$OSTYPE" == darwin*       ]]; }
is_android() { [[ "$OSTYPE" == linux-android ]]; }

command_exists() { command -v "$1" &>/dev/null; }

lazy_load() {
  local command="$1"
  local init_command="$2"

  eval "$command() {
    unfunction $command
    $init_command
    $command \$@
  }"
}

welcome() { "$ZSH_DOTFILES/welcome/main.py"; }

if is_android; then
  open_cmd='termux-open'
elif command_exists xdg-open; then
  open_cmd='nohup xdg-open &> /dev/null'
else
  open_cmd='print >&2 "open: Platform $OSTYPE is not supported"; return 1'
fi
eval "open(){$open_cmd \"\$@\";}"
unset open_cmd

if is_macos; then
  copy_cmd='pbcopy' paste_cmd='pbpaste'
elif command_exists xclip; then
  copy_cmd='xclip -in -selection clipboard' paste_cmd='xclip -out -selection clipboard'
elif command_exists xsel; then
  copy_cmd='xsel --clipboard --input' paste_cmd='xsel --clipboard --output'
elif command_exists termux-clipboard-set && command_exists termux-clipboard-get; then
  copy_cmd='termux-clipboard-set' paste_cmd='termux-clipboard-get'
else
  error_msg='Platform $OSTYPE is not supported'
  copy_cmd='print >&2 "clipcopy: '"$error_msg"'"; return 1'
  paste_cmd='print >&2 "clippaste: '"$error_msg"'"; return 1'
  unset error_msg
fi
eval "clipcopy(){$copy_cmd;};clippaste(){$paste_cmd;}"
unset copy_cmd paste_cmd
