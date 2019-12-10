#!/usr/bin/env zsh

count() { echo "$#"; }

bytecount() { wc -c "$@" | numfmt --to=iec-i; }

mkcd() { mkdir -p "$@" && cd "${@[-1]}"; }

viscd() {
  local temp_file chosen_dir
  temp_file="$(mktemp -t ranger_cd.XXXXXXXXXX)"
  ranger --choosedir="$temp_file" -- "${@:-$PWD}"
  if chosen_dir="$(<"$temp_file")" && [[ -n "$chosen_dir" && "$chosen_dir" != "$PWD" ]]; then
    cd -- "$chosen_dir"
  fi
  rm -f -- "$temp_file"
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

if ! is_macos; then
  if is_android; then
    open_cmd='termux-open'
  elif command_exists xdg-open; then
    open_cmd='nohup xdg-open &> /dev/null'
  else
    open_cmd='print >&2 "open: Platform $OSTYPE is not supported"; return 1'
  fi
  eval "open(){$open_cmd \"\$@\";}"
  unset open_cmd
fi

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

# for compatibility with Oh-My-Zsh plugins
# Source: https://github.com/robbyrussell/oh-my-zsh/blob/5911aea46c71a2bcc6e7c92e5bebebf77b962233/lib/git.zsh#L58-L71
git_current_branch() {
  if [[ "$(command git rev-parse --is-inside-work-tree)" != true ]]; then
    return 1
  fi

  local ref
  ref="$(
    command git symbolic-ref --quiet HEAD 2> /dev/null ||
    command git rev-parse --short HEAD 2> /dev/null
  )" || return
  echo "${ref#refs/heads/}"
}
