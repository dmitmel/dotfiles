#!/usr/bin/env zsh

prompt_escape() {
  echo "${@//'%'/%%}"
}

prompt_preexec_hook() {
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
  if [[ $(command git rev-parse --is-inside-work-tree) != true ]]; then
    return
  fi

  local branch="(no branches)" line
  git branch | while IFS= read -r line; do
    if [[ "$line" == "* "* ]]; then
      branch="${line#\* }"
      break
    fi
  done

  print -n ' %F{blue}git:(%F{magenta}'"$(prompt_escape "$branch")"'%F{blue})%f'
}

setup_prompt() {
  setopt nopromptbang promptcr promptsp promptpercent promptsubst

  zmodload zsh/datetime
  autoload -Uz add-zsh-hook
  add-zsh-hook preexec prompt_preexec_hook
  add-zsh-hook precmd prompt_precmd_hook

  PROMPT='%F{8}┌─%f%B'
  PROMPT+='%F{%(!.red.yellow)}%n%f'
  PROMPT+=' at %F{${SSH_CONNECTION:+blue}${SSH_CONNECTION:-green}}%m%f'
  PROMPT+=' in %F{cyan}%~%f'
  PROMPT+='$(prompt_vcs_info 2>/dev/null)'
  PROMPT+=' '
  PROMPT+='${_PROMPT_EXEC_TIME:+" %F{yellow}$(prompt_escape "$_PROMPT_EXEC_TIME")%f"}'
  PROMPT+='%(?.. %F{red}EXIT:%?%f)'
  PROMPT+='%1(j. %F{blue}JOBS:%j%f.)'
  PROMPT+=$'\n'
  PROMPT+='%b%F{8}└─%f'
  PROMPT+='%F{%(?.green.red)}%(!.#.\$)%f '

  PROMPT2='  %_> '
}

setup_prompt
