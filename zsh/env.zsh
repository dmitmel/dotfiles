#!/usr/bin/env zsh

# find editor
export EDITOR="nvim"
export VISUAL="$EDITOR"

export PAGER='less'
export LESS='--RAW-CONTROL-CHARS'

export CLICOLOR=1

# BSD ls colors
export LSCOLORS="Gxfxcxdxbxegedabagacad"
# GNU ls colors
if [[ -z "$LS_COLORS" ]] && command_exists dircolors; then
  eval "$(dircolors --bourne-shell)"
fi

# see COLORS in jq(1)
jq_colors=(
  "0;38;5;16" # null
  "0;38;5;16" # false
  "0;38;5;16" # true
  "0;38;5;16" # numbers
  "0;32"      # strings
  "0;39"      # arrays
  "0;39"      # objects
)
# join all values from jq_colors with a colon
export JQ_COLORS="${(j.:.)jq_colors}"
unset jq_colors

export HOMEBREW_NO_AUTO_UPDATE=1

# https://github.com/junegunn/fzf/blob/764316a53d0eb60b315f0bbcd513de58ed57a876/src/tui/tui.go#L496-L515
export FZF_DEFAULT_OPTS="--color=16 --height=40% --reverse"

# <https://github.com/sharkdp/bat#8-bit-themes>
export BAT_THEME="base16-256"

# <https://foss.heptapod.net/pypy/pypy/-/blob/release-pypy3.7-v7.3.5/lib_pypy/_pypy_irc_topic.py>
# <https://foss.heptapod.net/pypy/pypy/-/blob/release-pypy3.7-v7.3.5/lib_pypy/_pypy_interact.py#L17-27>
# <https://foss.heptapod.net/pypy/pypy/-/blob/release-pypy3.7-v7.3.5/pypy/interpreter/app_main.py#L892-896>
export PYPY_IRC_TOPIC=1
