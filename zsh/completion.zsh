# http://zsh.sourceforge.net/Doc/Release/Completion-System.html
# https://github.com/ohmyzsh/ohmyzsh/blob/master/lib/completion.zsh

# load fancier completion menu which (most notably) supports `list-colors`
zmodload zsh/complist
zstyle ':completion:*' menu select
# show even more completion results
zstyle ':completion:*' verbose yes

zstyle ':completion:*' use-cache yes
zstyle ':completion::*' cache-path "$ZSH_CACHE_DIR"

# group completion result based on their categories
zstyle ':completion:*' group-name ''
# format for displaying category names
zstyle ':completion:*:descriptions' format '%F{yellow}[%d]%f'

# Sometimes zsh completion authors for whatever reason add descriptions for
# option values, but don't do describe the options themselves (e.g. ffmpeg,
# some options for GCC). In such cases description of an option can be inferred
# from the description of its value. That's the purpose of `auto-description`.
zstyle ':completion:*:options' auto-description '%d'

# case insensitive (all), partial-word and substring completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z-_}={A-Za-z_-}' 'r:|=*' 'l:|=* r:|=*'

zstyle ':completion:*' list-dirs-first yes
# complete . and .. directories
# This is very useful when I just want to quickly look around inside a
# directory without running `ls`
zstyle ':completion:*' special-dirs yes

if [[ -n "$LS_COLORS" ]]; then
  zstyle ':completion:*' list-colors "${(@s.:.)LS_COLORS}"
fi

zstyle ':completion:*:processes' command "ps xo pid,user,cmd"
zstyle ':completion:*:processes-names' command "ps xho comm="
zstyle ':completion:*:processes' force-list always

_completion_get_hosts() {
  print -r -- localhost
  local line
  if [[ -r ~/.ssh/config ]]; then
    < ~/.ssh/config while IFS= read -r line; do
      if [[ "$line" =~ '^Host[[:blank:]]+(.*)[[:blank:]]*' ]]; then
        print -r -- "${match[1]}"
      fi
    done
  fi
}
zstyle -e ':completion:*:hosts' hosts 'reply=("${(@f)$(_completion_get_hosts)}")'

autoload -Uz compinit

run_compdump=1
# glob qualifiers description:
#   N    turn on NULL_GLOB for this expansion
#   .    match only plain files
#   m-1  check if the file was modified today
# see "Filename Generation" in zshexpn(1)
for match in "${ZSH_CACHE_DIR}/zcompdump"(N.m-1); do
  run_compdump=0
  break
done; unset match

# In both branches, -u disables the "security" (see the manpage) check and -d
# specifies the path to a completion dump.
if (( $run_compdump )); then
  print -r -- "$0: rebuilding zsh completion dump"
  # -D flag turns off compdump loading
  compinit -u -D -d "${ZSH_CACHE_DIR}/zcompdump"
  compdump
else
  # -C flag disables some checks performed by compinit - they are not needed
  # because we already have a fresh compdump
  compinit -u -C -d "${ZSH_CACHE_DIR}/zcompdump"
fi
unset run_compdump

if ! is_function _rustup && command_exists rustup; then
  lazy_load _rustup 'source <(rustup completions zsh)'
  compdef _rustup rustup
fi

if ! is_function _cargo && command_exists rustup && command_exists rustc; then
  lazy_load _cargo 'source "$(rustc --print sysroot)/share/zsh/site-functions/_cargo"'
  compdef _cargo cargo
fi

_wrapper_completion() {
  shift words
  (( CURRENT-- ))
  _normal
}
compdef _wrapper_completion prime-run allow-ptrace
