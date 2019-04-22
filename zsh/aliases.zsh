#!/usr/bin/env zsh

# This alias removes leading dollar sign. Useful when copying code from Stackoverflow
alias '$'=''

alias grep='grep --color=auto'

# exa is a modern replacement for ls - https://the.exa.website/
if command_exists exa; then
  alias ls="exa --classify --group-directories-first"
  alias lsa="${aliases[ls]} --all"
  alias l="${aliases[ls]} --long --header --binary --group"
  alias la="${aliases[l]} --all"
  alias tree="exa -T"
else
  alias ls="ls --classify --group-directories-first --color=auto"
  alias lsa="${aliases[ls]} --almost-all"
  alias l="${aliases[ls]} -l --human-readable"
  alias la="${aliases[l]} --almost-all"
fi

# fd is a simple, fast and user-friendly alternative to find - https://github.com/sharkdp/fd
if command_exists fd; then
  alias fda="fd --hidden --no-ignore"
else
  alias fd="find -iname"
  alias fda="${aliases[fd]}"
fi

# git with hub
command_exists hub && alias git="hub"

# make these utils more verbose
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -iv'
alias rmdir='rmdir -v'
alias chmod='chmod -v'
alias chown='chown -v'

# print file sizes in human readable format
alias du='du -h'
alias df='df -h'
