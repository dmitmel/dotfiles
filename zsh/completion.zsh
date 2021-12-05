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

autoload -U +X bashcompinit && bashcompinit
