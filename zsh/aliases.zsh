#!/usr/bin/env zsh

# this alias removes leading dollar sign (useful when copying code from Stackoverflow)
alias '$'=''

# the following aliases allow alias expansion in common programs which take
# commands as their arguments
alias sudo='sudo '
alias watch='watch '
alias xargs='xargs '

alias history='fc -i -l 1'

alias dirs='dirs -v'

alias grep='grep --color=auto'
alias diff='diff --color=auto --unified'

# exa is a modern replacement for ls - https://the.exa.website/
if command_exists exa; then
  alias ls='exa --classify --group-directories-first'
  alias lsa='ls --all'
  alias l='ls --long --header --binary --group'
  alias lt='l --tree'
  alias la='l --all'
  alias lat='la --tree'
  alias tree='ls --tree'
else
  alias ls='ls --classify --group-directories-first --color=auto'
  alias lsa='ls --almost-all'
  alias l='ls -l --human-readable'
  alias la='l --almost-all'
fi

# fd is a simple, fast and user-friendly alternative to find - https://github.com/sharkdp/fd
if command_exists fd; then
  alias fda='fd --hidden --no-ignore'
fi

# some amendments to Oh My Zsh's git plugin
# https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/git/git.plugin.zsh
alias glo="git log --decorate --abbrev-commit --date=relative --pretty='%C(auto)%h%C(reset)%C(auto)%d%C(reset) %s %C(green)- %an %C(blue)(%ad)%C(reset)'"
alias glog='glo --graph'
alias gloga='glog --all'

# git with hub
if command_exists hub; then
  alias git='hub'
  alias gw='git browse'
  alias gci='git ci-status --verbose'
fi

# make these utils more verbose
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -iv'
alias rmdir='rmdir -v' rd='rmdir'
alias chmod='chmod -v'
alias chown='chown -v'
alias chgrp='chgrp -v'
alias ln='ln -iv'
alias mkdir='mkdir -v' md='mkdir -p'

for n in {1..9}; do
  alias "$n"="cd +$n"
done; unset n

alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'

# print file sizes in human readable format
alias du='du -h'
alias df='df -h'
alias free='free -h'

if command_exists apt && command_exists apt-get; then
  apt_get_message="use 'apt' instead of 'apt-get'
if you really want to use 'apt-get', type '\\apt-get'"
  alias apt-get="print -r -- ${(qqq)apt_get_message} #"
  unset apt_get_message
fi

# editor
alias edit="$EDITOR"
alias e="$EDITOR"
if [[ "$EDITOR" == *vim ]]; then
  alias es="e -S"
fi

alias rsync-backup='rsync --archive --compress --verbose --human-readable --partial --progress'

if command_exists ncdu; then
  alias ncdu='ncdu --confirm-quit'
fi

alias bin-disassemble='objdump -M intel-mnemonics -d'
alias bin-list-symbols='nm'
alias bin-list-dylib-symbols='nm -gD'

# Duplicated as an alias to prevent autocorrection of the real "command" part.
# See also scripts/prime-run
alias prime-run='__NV_PRIME_RENDER_OFFLOAD=1 __VK_LAYER_NV_optimus=NVIDIA_only __GLX_VENDOR_LIBRARY_NAME=nvidia '

if ! command_exists update-grub; then
  # Doesn't exist on Arch by default. Probably implementing this command was
  # left as a challenge to the documentation reader.
  alias update-grub="grub-mkconfig -o /boot/grub/grub.cfg"
fi

if command_exists kitty && ! command_exists icat; then
  alias icat="kitty +kitten icat"
fi

alias bytefmt2="numfmt --to=iec-i --suffix=B"
alias bytefmt10="numfmt --to=si --suffix=B"

if command_exists dragon-drag-and-drop && ! command_exists dragon; then
  alias dragon='dragon-drag-and-drop'
fi

alias gtime="command time -v"

# Inspired by <https://github.com/junghans/cwdiff/blob/de56a73f37eb72edfb78ea610798a5744b8dcf10/cwdiff#L54-L61>.
alias cwdiff='wdiff --start-delete="${fg[red]}[-" --end-delete="-]${reset_color}" --start-insert="${fg[green]}{+" --end-insert "+}${reset_color}"'

alias yarn="yarn --emoji false"

# <https://mpv.io/manual/stable/#pseudo-gui-mode>
alias mpv='mpv --player-operation-mode=pseudo-gui'
