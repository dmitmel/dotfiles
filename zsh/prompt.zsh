#!/usr/bin/env zsh

# Escapes `%` in all arguments by replacing it with `%%`. Escaping is needed so
# that untrusted input (e.g. git branch names) doesn't affect prompt rendering.
prompt_escape() {
  print -n "${@//\%/%%}"
}

prompt_preexec_hook() {
  # record command start time
  # $EPOCHREALTIME returns a float representing system time in seconds (see
  # docs for zsh/datetime module) and is much faster than `date +%s.%N` because
  # it doesn't involve starting a process
  typeset -gF _PROMPT_EXEC_START_TIME="$EPOCHREALTIME"
}

prompt_precmd_hook() {
  if [[ -v _PROMPT_EXEC_START_TIME ]]; then
    local -F duration="$((EPOCHREALTIME - _PROMPT_EXEC_START_TIME))"
    unset _PROMPT_EXEC_START_TIME

    if (( duration > 1 )); then
      local -i t="$duration" d h m s
      typeset -g _PROMPT_EXEC_TIME=""
      d="$((t/60/60/24))"
      h="$((t/60/60%24))"
      m="$((t/60%60))"
      s="$((t%60))"
      (( d > 0 )) && _PROMPT_EXEC_TIME+="${d}d"
      (( h > 0 )) && _PROMPT_EXEC_TIME+="${h}h"
      (( m > 0 )) && _PROMPT_EXEC_TIME+="${m}m"
      _PROMPT_EXEC_TIME+="${s}s"
    else
      unset _PROMPT_EXEC_TIME
    fi
  fi
}

prompt_vcs_info() {
  if [[ "$(command git rev-parse --is-inside-work-tree)" != true ]]; then
    return
  fi

  local branch="(no branches)" line
  command git branch | while IFS= read -r line; do
    # find a line which starts with `* `, it contains the current branch name
    if [[ "$line" == "* "* ]]; then
      # remove the `* ` prefix
      branch="${line#\* }"
      break
    fi
  done

  print -n ' %F{blue}git:%F{magenta}'"$(prompt_escape "$branch")"'%f'
}

# configure prompt expansion
# nopromptbang
#   `!` should not be treated specially, use `%!` instead.
# promptcr and promptsp
#   print a character (`%` for normal users, `#` for root) and a newline in
#   order to preserve output that may be covered by the prompt. See
#   zshoptions(1) for more details.
# promptpercent
#   enable normal prompt expansion sequences which begin with a `%`.
# promptsubst
#   enable parameter/command/arithmetic expansion/substitution in the prompt.
setopt no_prompt_bang prompt_cr prompt_sp prompt_percent prompt_subst

zmodload zsh/datetime
autoload -Uz add-zsh-hook
add-zsh-hook preexec prompt_preexec_hook
add-zsh-hook precmd prompt_precmd_hook

# Construct the prompt. See EXPANSION OF PROMPT SEQUENCES in zshmisc(1) for
# the list and descriptions of the expansion sequences.

# Start the prompt with gray (ANSI color 8 is "bright black" or "gray")
# box drawing characters, also enable bold font for the rest of it. This
# makes the prompt easily distinguishable from command output.
PROMPT='%F{8}┌─%f%B'

# username
PROMPT+='%F{%(!.red.yellow)}%n%f'

# hostname
PROMPT+=' at %F{'
if [[ -v SSH_CONNECTION ]]; then
  PROMPT+='blue'
else
  PROMPT+='green'
fi
PROMPT+='}%m%f'

# working directory
PROMPT+=' in %F{cyan}%~%f'

# VCS info
PROMPT+='$(prompt_vcs_info 2>/dev/null)'

# Python's virtualenv
PROMPT+='${VIRTUAL_ENV:+" %F{blue}venv:%F{magenta}${VIRTUAL_ENV:t}%f"}'
VIRTUAL_ENV_DISABLE_PROMPT=true

# pyenv
PROMPT+='${PYENV_VERSION:+" %F{blue}pyenv:%F{magenta}${PYENV_VERSION:t}%f"}'
PYENV_VIRTUAL_ENV_DISABLE_PROMPT=true

PROMPT+=' '

# command execution time
PROMPT+='${_PROMPT_EXEC_TIME:+" %F{yellow}$(prompt_escape "$_PROMPT_EXEC_TIME")%f"}'

# exit code of the previous command
PROMPT+='%(?.. %F{red}EXIT:%?%f)'

# number of currently running background jobs
PROMPT+='%1(j. %F{blue}JOBS:%j%f.)'

# A while ago I decided to start using a multiline prompt because:
# a) all commands I type are visually aligned
# b) I can type pretty long commands without text wrapping in small terminal
#    windows (e.g. in Termux on my phone)
PROMPT+=$'\n'

# see prompt beginning
PROMPT+='%b%F{8}└─%f'

# the last character
PROMPT+='%F{%(?.green.red)}%(!.#.\$)%f '

# PROMPT2 is used when you type an unfinished command. Spaces are needed for
# alignment with normal PROMPT.
PROMPT2='  %_> '
