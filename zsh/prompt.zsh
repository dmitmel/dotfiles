zmodload zsh/datetime  # for $EPOCHREALTIME
autoload -Uz add-zsh-hook

# The installation of hooks for measuring command execution time is deferred
# until after the shell is initialized and the first prompt is drawn. This is
# done so that this script can control the order of placement of its hooks, so
# that it doesn't depend on the load order of other scripts and plugins.
add-zsh-hook precmd _prompt_install_hooks
_prompt_install_hooks() {
  add-zsh-hook -d preexec _prompt_install_hooks  # uninstall this temporary hook
  unfunction _prompt_install_hooks               # and unload it from memory

  # I manipulate the `*_functions` arrays directly here because `add-zsh-hook`
  # does not let me control the placement order. To get the most accurate
  # assessment of the run-time of a command, we must achieve the following
  # sequence of events:
  #
  # 1. user types in a command and presses <Enter>
  # 2. preexec hooks are executed
  # 3. **prompt_preexec_hook is executed and records the start time**
  # 4. ...the command runs...
  # 5. the command exits
  # 6. **prompt_precmd_hook is executed and records the stop time**
  # 7. all other precmd hooks are executed
  # 8. a new prompt is drawn
  typeset -ag preexec_functions=("${preexec_functions[@]:#prompt_preexec_hook}" prompt_preexec_hook)
  typeset -ag precmd_functions=(prompt_precmd_hook "${precmd_functions[@]:#prompt_precmd_hook}")
}

prompt_preexec_hook() {
  # $EPOCHREALTIME returns a float representing the system time in seconds (see
  # docs for the zsh/datetime module). It is much faster than `date +%s.%N`
  # because it doesn't involve forking another process.
  float -g _PROMPT_EXEC_START_TIME="$EPOCHREALTIME"
}

prompt_precmd_hook() {
  if [[ -v _PROMPT_EXEC_START_TIME ]]; then
    float t=$(( EPOCHREALTIME - _PROMPT_EXEC_START_TIME ))
    unset _PROMPT_EXEC_START_TIME

    typeset -g _PROMPT_EXEC_TIME=""
    if (( t > 1 )); then
      integer d h m s
      (( d = t/60/60/24, h = t/60/60%24, m = t/60%60, s = t%60 ))
      (( d > 0 )) && _PROMPT_EXEC_TIME+="${d}d"
      (( h > 0 )) && _PROMPT_EXEC_TIME+="${h}h"
      (( m > 0 )) && _PROMPT_EXEC_TIME+="${m}m"
      _PROMPT_EXEC_TIME+="${s}s"
    else
      integer ms
      (( ms = t * 1000 ))
      _PROMPT_EXEC_TIME="${ms}ms"
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

  # Be sure to escape `%` in the branch name by replacing them with `%%`, so
  # that untrusted input does not affect prompt rendering.
  print -rn -- " %F{blue}git:%F{magenta}${branch//\%/%%}%f"
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

# current time
PROMPT+=' [%F{red}%D %*%f]'

# VCS info
PROMPT+='$(prompt_vcs_info 2>/dev/null)'

# Python's virtualenv
PROMPT+='${VIRTUAL_ENV:+" %F{blue}venv:%F{magenta}${VIRTUAL_ENV:t//\%/%%}%f"}'
VIRTUAL_ENV_DISABLE_PROMPT=true

# pyenv
PROMPT+='${PYENV_VERSION:+" %F{blue}pyenv:%F{magenta}${PYENV_VERSION//\%/%%}%f"}'
PYENV_VIRTUAL_ENV_DISABLE_PROMPT=true

PROMPT+=' '

# command execution time
PROMPT+='${_PROMPT_EXEC_TIME:+" %F{yellow}${_PROMPT_EXEC_TIME//\%/%%}%f"}'

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
