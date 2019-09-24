#!/usr/bin/env zsh

# this alias removes leading dollar sign (useful when copying code from Stackoverflow)
alias '$'=''
# this alias allows aliases to work with sudo
alias sudo='sudo '

alias history='fc -i -l 1'

alias cdd='dirs -v'

alias grep='grep --color=auto'
alias diff='diff --color=auto'

# exa is a modern replacement for ls - https://the.exa.website/
if command_exists exa; then
  alias ls="exa --classify --group-directories-first"
  alias lsa="ls --all"
  alias l="ls --long --header --binary --group"
  alias la="l --all"
  alias tree="ls --tree"
else
  alias ls="ls --classify --group-directories-first --color=auto"
  alias lsa="ls --almost-all"
  alias l="ls -l --human-readable"
  alias la="l --almost-all"
fi

# fd is a simple, fast and user-friendly alternative to find - https://github.com/sharkdp/fd
if command_exists fd; then
  alias fda="fd --hidden --no-ignore"
fi

# git with hub
if command_exists hub; then
  alias git="hub"
fi

# make these utils more verbose
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -iv'
alias rmdir='rmdir -v' rd='rmdir'
alias chmod='chmod -v'
alias chown='chown -v'
alias ln='ln -iv'
alias mkdir='mkdir -v' md='mkdir -p'

for n in {1..9}; do
  alias "$n"="cd +$n"
done; unset n

alias ...='../..'
alias ....='../../..'
alias .....='../../../..'
alias ......='../../../../..'

# print file sizes in human readable format
alias du='du -h'
alias df='df -h'
alias free='free -h'

alias apt-get="echo -e \"use 'apt' instead of 'apt-get'\nif you really want to use 'apt-get', type '"'\\\\'"apt-get'\" #"
