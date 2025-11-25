# Prints the number of received arguments.
count() { print -r -- "$#"; }
# Prints all arguments on separate lines. Useful for inspecting the contents of
# arrays, like this: `print_lines $fpath`.
print_lines() { print -rC1 -- "$@"; }
# Prints the arguments as a NUL-terminated list.
print_null() { print -rNC1 -- "$@"; }
# Prints an associative array as a 2-column table for its keys and values.
# Intended for debugging. Explanations of the used parameter expansion flags:
#   P   reference another variable by its name, in this case taken from `$1`
#  @kv  assuming this variable refers to an associative array, expand it into a
#       list of consecutive key-value pairs
#   q+  quote the expanded items when necessary, the same way as `declare -p`
# Explanations of the `print` flags:
#  -r   print raw strings, don't expand backslash-escape sequences
#  -C2  format the output into two columns
#  -a   in a row-major order
print_table() { print -raC2 -- "${(P@kvq+)1}"; }
# complete the names of associative array variables for `print_table`
compdef '_parameters -g "association*"' print_table
# Checks if the array referred to by the name in the 1st argument contains the
# string in the 2nd argument. The condition is a more complicated form of
# `${array[(re)$elem]+1}`, which expands to `1` if `$array` contains `$elem`.
contains() { [[ -n "${${(P)1}[(re)${2}]+1}" ]]; }

# Checks if a word can be meaningfully executed as a command (aliases, functions
# and builtins also count).
command_exists() { whence -- "$@" &>/dev/null; }
# Searches the command binary in PATH.
command_locate() { whence -p -- "$@"; }

is_function() { typeset -f -- "$@" &>/dev/null; }
is_alias() { alias -- "$@" &>/dev/null; }
is_command() { whence -p -- "$@" &>/dev/null; }

lazy_load() {
  local name="$1"
  local init="$2"
  functions[$name]="
    unfunction ${(q)name}
    eval ${(q+)init}
    ${(q)name} \"\$@\"
  "
}

# A helper for writing code for caching stuff that might change depending on
# some inputs. Inspired by the syntax of makefiles: `target: dep1 dep2 dep3`.
should_rebuild() {
  local target="$1" dependency=""; shift 1
  # no if any dependency does not exist
  for dependency; do if [[ ! -e "$dependency" ]]; then return 1; fi; done
  # yes if the target does not exist
  if [[ ! -e "$target" ]]; then return 0; fi
  # yes if any dependency is newer than the target
  for dependency; do if [[ "$dependency" -nt "$target" ]]; then return 0; fi; done
  return 1  # no, the target is up-to-date
}

bytecount() { wc -c -- "$@" | numfmt --to=iec-i --suffix=B; }

mkcd() { mkdir -pv -- "$@" && cd -- "${@[-1]}"; }

lfcd() {
  local dir
  if dir="$(command lf -print-last-dir "$@")" && [[ -n "$dir" && "$dir" != "$PWD" ]]; then
    cd -- "$dir"
  fi
}

if [[ "$OSTYPE" != darwin* ]]; then
  if [[ "$OSTYPE" == linux-android* ]]; then
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

if [[ "$OSTYPE" == darwin* ]]; then
  copy_cmd='pbcopy' paste_cmd='pbpaste'
elif [[ "$OSTYPE" == linux-android* ]]; then
  copy_cmd='termux-clipboard-set' paste_cmd='termux-clipboard-get'
elif command_exists xclip; then
  copy_cmd='xclip -in -selection clipboard' paste_cmd='xclip -out -selection clipboard'
elif command_exists xsel; then
  copy_cmd='xsel --clipboard --input' paste_cmd='xsel --clipboard --output'
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

if is_command swapoff && is_command swapon; then
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
  integer length="${DIRSTACKSIZE:-${#saved_dirs[@]}}"
  print_lines "${saved_dirs[@]:0:${length}}" >| "$DIRSTACK_FILE"
}

dirstack_load() {
  local saved_dirs
  if saved_dirs="$(<"$DIRSTACK_FILE")" 2>/dev/null; then
    # remove PWD from the saved dirstack using the array uniqueness feature
    local -aU saved_dirs=("$PWD" "${(@f)saved_dirs:#$PWD}")
    integer length="${DIRSTACKSIZE:-${#saved_dirs[@]}}"
    # skip the first entry in the loaded list, which corresponds to $PWD
    dirstack=("${saved_dirs[@]:1:${length}-1}")
  fi
}

discord-avatar() {
  if (( $# != 1 )); then
    print >&2 "Usage: $0 [user_snowflake]"
    return 1
  fi
  local url
  if url="$(discord-whois --image-size 4096 --get 'Avatar' "$1")"; then
    open "$url"
  fi
}

zmodload zsh/langinfo
# Based on <https://gist.github.com/lucasad/6474224> and
# <https://github.com/ohmyzsh/ohmyzsh/blob/aca048814b2462501ab82938ff2473661182fffb/lib/functions.zsh#L130-L209>.
omz_urlencode() {
  emulate -L zsh -o extended_glob

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
  ${=EDITOR:-nvim} =(nvim --startuptime /dev/stdout --headless -c 'qall!')
}

vim-startuptime() {
  ${=EDITOR:-vim} =(vim --startuptime /dev/stdout --not-a-term -c 'qall!')
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
compdef _precommand allow-ptrace

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
  # Capture the output of `z -l` into an array of lines.
  local lines=("${(@f)$(z -l)}")
  # Apply a replacement on every element of `$lines`, removing the first column
  # with numeric scores. `(*)` enables `EXTENDED_GLOB` for this substitution.
  local paths=("${(*)lines[@]/#[0-9]## ##/}")
  # Format the paths for display in the picker. The `(D)` will try to shorten
  # every path in the array by replacing the leading part with `~` or `~name` if
  # it corresponds to $HOME or a named directory. `(Q)` removes unnecessary
  # quoting and escapes introduced by `(D)`, and `(V)` will format unprintable
  # characters (if a path contains them) in such a way as to make them visible.
  local choices=("${(@QV)${(@D)paths}}")
  integer selected
  # Pipe `choices` into fzf as a list of lines.
  if selected="$(fzf <<<"${(F)choices}" --accept-nth='{n}' --tac --scheme=path --query="$*")"; then
    # Indexes returned by fzf are zero-based, while in Zsh they are one-based.
    cd -- "${paths[selected + 1]}"
  fi
}

d() {
  integer selected
  # `dirs -pv` prints a numbered list of directories in the dirstack. Notice the
  # abscence of the flag `-l` -- it would cause $HOME and named directories to
  # be expanded into full paths instead of being displayed with `~` shorthands.
  if selected="$(builtin dirs -pv | fzf --accept-nth=1 --scheme=path --query="$*" --cycle)"; then
    # fzf will return the number from the first column of the output of `dirs`,
    # which neatly corresponds to 1-based indexes in the `$dirstack`.
    if (( selected > 0 )); then cd -- "${dirstack[selected]}"; fi
  fi
}

fzf-man() {
  # Previewer code is based on <https://github.com/ibhagwan/fzf-lua/blob/3170d98240266a68c2611fc63260c3ab431575aa/lua/fzf-lua/defaults.lua#L27-L40>
  local previewer='MANPAGER=cat MANWIDTH=$FZF_PREVIEW_COLUMNS man {1} {2} 2>/dev/null'
  local bat; for bat in batcat bat; do
    if is_command "$bat"; then
      previewer+=" | ${bat} --style=plain --language=man --color=always"
      break
    fi
  done
  if [[ -z "$bat" ]]; then
    # Why this is necessary: <https://unix.stackexchange.com/questions/15855/how-to-dump-a-man-page#comment638382_15866>
    previewer+=' | col -bx'
  fi

  man -k . | sed 's/^\s*\(\S\+\)\s*(\(\w\+\))/\2 \1 \0/' |
    fzf --with-nth=3.. --accept-nth=1,2 --tiebreak=begin,chunk --query="$*" --preview="$previewer"
}

# A tool for debugging whether a given user can access the provided path.
access() {
  local user="${1?:need a username}"; shift
  sudo -u "$user" namei --owners --modes --mountpoints -- "$@"
}
compdef 'if (( CURRENT > 2 )); then _files; else _users; fi' access
