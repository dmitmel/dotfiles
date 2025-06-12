#!/usr/bin/env zsh

count() { print -r -- "$#"; }

bytecount() { wc -c "$@" | numfmt --to=iec-i --suffix=B; }

mkcd() { mkdir -p -- "$@" && cd -- "${@[-1]}"; }

viscd() {
  setopt local_options err_return
  local temp_file chosen_dir
  temp_file="$(mktemp -t ranger_cd.XXXXXXXXXX)"
  {
    ranger --choosedir="$temp_file" -- "${@:-$PWD}"
    if chosen_dir="$(<"$temp_file")" && [[ -n "$chosen_dir" && "$chosen_dir" != "$PWD" ]]; then
      cd -- "$chosen_dir"
    fi
  } always {
    rm -f -- "$temp_file"
  }
}

# Checks if a word can be meaningfully executed as a command (aliases,
# functions and builtins also count).
command_exists() { whence -- "$@" &>/dev/null; }
is_function() { typeset -f -- "$@" &>/dev/null; }
is_alias() { alias -- "$@" &>/dev/null; }
is_command() { whence -p -- "$@" &>/dev/null; }
# Searches the command binary in PATH.
command_locate() { whence -p -- "$@"; }

lazy_load() {
  local command="$1"
  local init_command="$2"

  eval "$command() {
    unfunction $command
    $init_command
    $command \$@
  }"
}

if (( ! _is_macos )); then
  if (( _is_android )); then
    open_cmd='termux-open'
  elif command_exists xdg-open; then
    open_cmd='nohup xdg-open &> /dev/null'
  else
    open_cmd='print >&2 -r -- "open: Platform $OSTYPE is not supported"; return 1'
  fi
  # "${@:-.}" will substitute either the list of arguments, or the current
  # directory if no arguments were given.
  eval "open(){local f; for f in \"\${@:-.}\"; do $open_cmd \"\$f\"; done;}"
  unset open_cmd
fi

if (( _is_macos )); then
  copy_cmd='pbcopy' paste_cmd='pbpaste'
elif command_exists xclip; then
  copy_cmd='xclip -in -selection clipboard' paste_cmd='xclip -out -selection clipboard'
elif command_exists xsel; then
  copy_cmd='xsel --clipboard --input' paste_cmd='xsel --clipboard --output'
elif command_exists termux-clipboard-set && command_exists termux-clipboard-get; then
  copy_cmd='termux-clipboard-set' paste_cmd='termux-clipboard-get'
else
  error_msg='Platform $OSTYPE is not supported'
  copy_cmd='print >&2 -r -- "clipcopy: '"$error_msg"'"; return 1'
  paste_cmd='print >&2 -r -- "clippaste: '"$error_msg"'"; return 1'
  unset error_msg
fi
eval "clipcopy() { $copy_cmd; }; clippaste() { $paste_cmd; }"
unset copy_cmd paste_cmd

# for compatibility with Oh My Zsh plugins
# Source: https://github.com/ohmyzsh/ohmyzsh/blob/5911aea46c71a2bcc6e7c92e5bebebf77b962233/lib/git.zsh#L58-L71
git_current_branch() {
  if [[ "$(command git rev-parse --is-inside-work-tree)" != true ]]; then
    return 1
  fi

  local ref
  ref="$(
    command git symbolic-ref --quiet HEAD 2> /dev/null ||
    command git rev-parse --short HEAD 2> /dev/null
  )" || return
  print -r -- "${ref#refs/heads/}"
}

declare -A date_formats=(
  iso       '%Y-%m-%dT%H:%M:%SZ'
  normal    '%Y-%m-%d %H:%M:%S'
  compact   '%Y%m%d%H%M%S'
  only-date '%Y-%m-%d'
  only-time '%H:%M:%S'
  timestamp '%s'
)

for format_name format in "${(kv)date_formats[@]}"; do
  eval "date-fmt-${format_name}() { date +${(q)format} \"\$@\"; }"
done; unset format_name format

unset date_formats

if (( _is_linux )) && command_exists swapoff && command_exists swapon; then
  deswap() { sudo sh -c 'swapoff --all && swapon --all'; }
fi

# Taken from <https://vi.stackexchange.com/a/7810/34615>
sudoedit() {
  SUDO_COMMAND="sudoedit $@" command sudoedit "$@"
}
alias sudoe="sudoedit"
alias sue="sudoedit"

# <https://github.com/ohmyzsh/ohmyzsh/blob/706b2f3765d41bee2853b17724888d1a3f6f00d9/plugins/last-working-dir/last-working-dir.plugin.zsh>
# <https://unix.stackexchange.com/questions/274909/how-can-i-get-a-persistent-dirstack-with-unique-entries-in-zsh>
# <https://wiki.archlinux.org/title/Zsh#Dirstack>
DIRSTACK_FILE="${XDG_DATA_HOME:-$HOME/.local/share}/zsh_dirstack.txt"

autoload -Uz add-zsh-hook

dirstack_save_hook() {
  if [[ -z "$DOTFILES_DONT_SYNC_DIRSTACK" && "$ZSH_SUBSHELL" -eq 0 ]]; then
    dirstack_save
  fi
}
add-zsh-hook chpwd dirstack_save_hook

dirstack_load_hook() {
  if [[ -z "$DOTFILES_DONT_SYNC_DIRSTACK" && "$ZSH_SUBSHELL" -eq 0 ]]; then
    dirstack_load
  fi
}
add-zsh-hook precmd dirstack_load_hook
add-zsh-hook preexec dirstack_load_hook

dirstack_save() {
  # declare a local array with unique elements (only the first occurence of
  # each word is persisted)
  local -aU saved_dirs=("$PWD" "${dirstack[@]}")
  print_lines "${saved_dirs[@]}" >| "$DIRSTACK_FILE"
}

dirstack_load() {
  local saved_dirs
  if saved_dirs="$(<"$DIRSTACK_FILE")" 2>/dev/null; then
    # remove PWD from the saved dirstack using the array uniqueness feature
    local -aU saved_dirs=("$PWD" "${(@f)saved_dirs}")
    # skip the first entry in the saved dirstack
    dirstack=("${saved_dirs[@]:1}")
  fi
}

discord-avatar() {
  setopt local_options err_return
  if (( $# != 1 )); then
    print >&2 "Usage: $0 [user_snowflake]"
    return 1
  fi
  local avatar_url
  avatar_url="$(discord-whois --image-size 4096 --get 'Avatar' "$1")"
  open "$avatar_url"
}

read_line() {
  IFS= read -r -- "$@"
}

print_lines() {
  print -rC1 -- "$@"
}

print_null() {
  print -rNC1 -- "$@"
}

zmodload zsh/langinfo
# Based on <https://gist.github.com/lucasad/6474224> and
# <https://github.com/ohmyzsh/ohmyzsh/blob/aca048814b2462501ab82938ff2473661182fffb/lib/functions.zsh#L130-L209>.
omz_urlencode() {
  emulate -L zsh -o extendedglob

  local -A opts
  # -D: Remove all parsed options from the list of arguments, i.e. $@
  # -E: Ignore unknown options, treating them as positional arguments
  # -A: Put the parsed options into an associative array
  zparseopts -D -E -A opts r m P
  local str="$*"

  local encoding="${langinfo[CODESET]}"
  if [[ "$encoding" != (UTF-8|utf8|US-ASCII) ]]; then
    if ! str="$(iconv -f "$encoding" -t UTF-8 <<< "$str")"; then
      print >&2 -r -- "Error converting string from ${encoding} to UTF-8"
      return 1
    fi
  fi

  local unescaped="A-Za-z0-9"
  if (( ! ${+opts[-P]} )); then unescaped+="+"; fi
  if (( ! ${+opts[-r]} )); then unescaped+=";/?:@&=+$,"; fi
  if (( ! ${+opts[-m]} )); then unescaped+="_.!~*'()-"; fi

  # Replace spaces with plus signs if necessary.
  if (( ! ${+opts[-P]} )); then str=${str:gs/ /+} fi
  # Split the string into a list of characters.
  local chars=( ${(s::)str} )
  # The following cryptic oneliner essentially iterates over the `chars` list,
  # and applies an expression to every character which replaces the characters
  # not in the `unescaped` set with their (zero-padded) percent-encoding.
  str=${(j::)chars/(#b)([^${~unescaped}])/%${(l:2::0:)$(([##16]#match))}}

  print -r -- "${str}"
}

nvim-startuptime() {
  "$EDITOR" =(nvim --startuptime /dev/stdout --headless -c 'qall!')
}

vim-startuptime() {
  "$EDITOR" =(vim --startuptime /dev/stdout --not-a-term -c 'qall!')
}

allow-ptrace() {
  local program
  if ! program="$(command_locate "$1")"; then
    printf "$0: command not found: %s\n" "$1"
    return 1
  fi
  shift
  # <https://wiki.archlinux.org/title/Capabilities#Running_a_program_with_temporary_capabilities>
  sudo -E capsh \
    --caps="cap_setpcap,cap_setuid,cap_setgid+ep cap_sys_ptrace+eip" \
    --keep=1 --user="$USER" --addamb="cap_sys_ptrace" --shell="$program" -- "$@"
}

check-ssd-health() {
  sudo smartctl -l devstat "$1" | grep --color=always 'Percentage Used Endurance Indicator\|$'
}

scan-local-network() {
  local subnets=( $(command ip -4 route | awk '$1 ~ /\// { print $1 }') )
  # <https://nmap.org/book/reduce-scantime.html>
  # -sn -- just a ping scan, without scanning ports
  # -n  -- disable DNS resolution of scanned hosts
  nmap -sn -n "${subnets[@]}" --stats-every 1s
}

j() {
  local selected
  if selected=( $(z -l | fzf --with-nth=2.. --tac --tiebreak=index --query="$*") ); then
    cd -- "${selected[2]}"
  fi
}

d() {
  local selected
  if selected=( $(builtin dirs -p | fzf --tiebreak=index --query="$*") ); then
    cd -- "${selected[2]}"
  fi
}

fzf-man() {
  local selected
  if selected="$(man -k . | fzf --tiebreak=begin --query="$*")"; then
    if [[ $selected =~ '^[[:space:]]*([^[:space:]]+)[[:space:]]*\(([[:alnum:]]+)\)' ]]; then
      printf "%s %s\n" "${match[2]} ${match[1]}"
      return 0
    fi
  fi
  return 1
}
