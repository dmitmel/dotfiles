# Configure prompt expansion (see zshoptions(1) for more details):

# 1. `!` should not be treated specially, use `%!` instead
setopt no_prompt_bang
# 2. Print a character (`%` for normal users, `#` for root) and a newline in
#    order to preserve output that may be covered by the prompt.
setopt prompt_cr prompt_sp
# 3. Enable normal prompt expansion sequences which begin with a `%`.
setopt prompt_percent
# 4. Enable parameter/command/arithmetic expansion/substitution in the prompt.
setopt prompt_subst

zmodload zsh/datetime  # for $EPOCHREALTIME
autoload -Uz add-zsh-hook

# The installation of hooks for measuring command execution time is deferred
# until after the shell is initialized and the first prompt is drawn. This is
# done so that this script can control the order of placement of its hooks, so
# that it doesn't depend on the load order of other scripts and plugins.
_prompt_install_hooks() {
  add-zsh-hook -d preexec _prompt_install_hooks  # uninstall this temporary hook
  unfunction _prompt_install_hooks               # and unload it from memory

  # I manipulate the `*_functions` arrays directly here because `add-zsh-hook`
  # does not let me control the placement order. To get the most accurate
  # assessment of the run-time of an interactively entered command, we must
  # achieve the following sequence of events:
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
  if (( ${+_PROMPT_EXEC_START_TIME} )); then  # check if this variable is defined
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
      integer ms=$(( t * 1000 ))
      _PROMPT_EXEC_TIME="${ms}ms"
    fi
  fi
}

add-zsh-hook precmd _prompt_install_hooks
add-zsh-hook precmd prompt_precmd_hook
add-zsh-hook preexec prompt_preexec_hook

prompt_vcs_info() {
  if [[ "$(command git rev-parse --is-inside-work-tree)" != true ]]; then
    return
  fi

  local branch="(no branches)" line=""
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

# Construct the prompt. See EXPANSION OF PROMPT SEQUENCES in zshmisc(1) for the
# list and descriptions of the expansion sequences.

# Start the prompt with gray (ANSI color 8 is "bright black" or "gray") box
# drawing characters, also enable bold font for the rest of it. This makes the
# prompt easily distinguishable from command output.
PROMPT='%F{8}┌─%f%B'

# username
PROMPT+='%F{%(!.red.yellow)}%n%f'

# Make hostname blue if we are connected to a remote machine. I used to check
# $SSH_CONNECTION to determine this, but apparently $SSH_TTY works better for
# that: compare how they behave when attaching through SSH to a tmux session
# started from a local terminal. $SSH_CONNECTION is inserted into environment of
# tabs/windows created from a remote terminal and $SSH_TTY is not. When working
# simultaneously from local and remote terminals (I sometimes do that if I SSH
# from one of my laptops into the other one to work from both of them) using
# $SSH_CONNECTION here creates a mix of tabs where some shells consider
# themselves local and some remote, which is just inconsistent and annoys me.
# Besides, checking $SSH_TTY matches the behavior of Kitty's shell integration
# script, which is responsible for setting the title of the terminal session:
# <https://github.com/kovidgoyal/kitty/blob/v0.45.0/shell-integration/zsh/kitty-integration#L257-L269>
# Other environment variables which tmux reads from the currently used client:
# <https://github.com/tmux/tmux/blob/3.6/options-table.c#L981-L982>.
PROMPT+=' at %F{${${SSH_TTY:+blue}:-green}}%m%f'

# working directory
PROMPT+=' in %F{cyan}%~%f'

# current time
PROMPT+=' [%F{red}%D %*%f]'

# VCS info
PROMPT+='$(prompt_vcs_info 2>/dev/null)'

# Python's virtualenv
PROMPT+='${VIRTUAL_ENV:+" %F{blue}venv:%F{magenta}${${VIRTUAL_ENV:t}//\%/%%}%f"}'
VIRTUAL_ENV_DISABLE_PROMPT=true

# pyenv
PROMPT+='${PYENV_VERSION:+" %F{blue}pyenv:%F{magenta}${PYENV_VERSION//\%/%%}%f"}'
PYENV_VIRTUAL_ENV_DISABLE_PROMPT=true

# lf
PROMPT+='${LF_LEVEL:+" %F{blue}lf:%F{magenta}${LF_LEVEL//\%/%%}%f"}'

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

# Begin the second line of the prompt.
PROMPT+='%b%F{8}└─'

# The prompt ends with a dollar sign for regular users and a hash for root,
# repeated as many times as there are nested shells.
for (( i = DOTFILES_STARTING_SHLVL + 1; i < SHLVL; i++ )); do
  PROMPT+='%(!.#.\$)'
done; unset i

# The final dollar/hash sign is normally colored green, but becomes red if the
# last command has exited with a non-zero code.
PROMPT+='%F{%(?.green.red)}%(!.#.\$)%f '
