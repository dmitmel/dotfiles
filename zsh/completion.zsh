# http://zsh.sourceforge.net/Doc/Release/Completion-System.html
# https://github.com/ohmyzsh/ohmyzsh/blob/master/lib/completion.zsh

# load fancier completion menu which (most notably) supports `list-colors`
zmodload zsh/complist
zstyle ':completion:*' menu select
# show even more completion results
zstyle ':completion:*' verbose yes

zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "$ZSH_CACHE_DIR"

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

_complete_ssh_hosts() {
  reply=( localhost )
  local line
  if [[ -r ~/.ssh/config ]]; then
    < ~/.ssh/config while IFS= read -r line; do
      if [[ "$line" =~ '^Host[[:blank:]]+(.*)[[:blank:]]*' ]]; then
        reply+=("${match[1]}")
      fi
    done
  fi
}
zstyle -e ':completion:*:hosts' hosts '_complete_ssh_hosts'

zcompdump="${ZSH_CACHE_DIR}/zcompdump"

# Delete the completion dump if it is stale. Description of the glob qualifiers:
#   N    turn on NULL_GLOB for this expansion
#   .    match only plain files
#   m+0  check if the file was modified more than a day ago
# see "Filename Generation" in zshexpn(1).
for stale in "$zcompdump"(N.m+0); do
  print >&2 -r -- "deleting stale completion dump at ${(qq)stale}"
  command rm -- "$stale"
done; unset stale

# -u disables the "security check", see "Use of compinit" in zshcompsys(1), and
# -d specifies the path to a completion dump file. -w was only added in a recent
# version of Zsh and prints the reason for updating the compdump if that happens
# (<https://github.com/zsh-users/zsh/commit/6f4cf791405e74925c497bf3493bcd834918cf85>).
autoload -Uz compinit is-at-least && \
  compinit -u -d "$zcompdump" $(if is-at-least '5.8.1.2'; then print -- '-w'; fi)

# Speed up shell initialization by compiling the compdump. The code is from
# <https://github.com/sorin-ionescu/prezto/blob/c945922b2268ca1959a3ed29368b1c21a07950c1/runcoms/zlogin#L11-L17>.
# See also: <https://github.com/sorin-ionescu/prezto/issues/2028>, <https://github.com/ohmyzsh/ohmyzsh/pull/11345>.
if [[ -s "$zcompdump" && (! -s "${zcompdump}.zwc" || "$zcompdump" -nt "${zcompdump}.zwc") ]]; then
  if command mkdir -- "${zcompdump}.zwc.lock" 2>/dev/null; then
    zcompile -R -- "$zcompdump"
    command rmdir -- "${zcompdump}.zwc.lock" 2>/dev/null
  fi
fi

eval "${(F)_deferred_compdefs}"  # the (F) flag joins all items of an array with newlines
unset _deferred_compdefs

if ! is_function _rustup && command_exists rustup; then
  lazy_load _rustup 'source <(rustup completions zsh)'
  compdef _rustup rustup
fi

if is_function _rustup; then
  # For some reason, the completions provided by the default script for Rustup
  # are off-by-one: you get an autocompletion for a subcommand twice, i.e. the
  # first argument, and arguments after that are completed just fine. Fix that
  # by tricking the existing `_rustup` function into thinking that a word has
  # already been typed. See <https://github.com/rust-lang/rustup/issues/2268>.
  _rustup_fixed() {
    words=(rustup "${words[@]}")
    (( CURRENT += 1 ))
    _rustup "$@"
  }
  compdef _rustup_fixed rustup
fi

if ! is_function _cargo && command_exists rustup && command_exists rustc; then
  lazy_load _cargo 'source "$(rustc --print sysroot)/share/zsh/site-functions/_cargo"'
  compdef _cargo cargo
fi

compdef _precommand prime-run allow-ptrace
