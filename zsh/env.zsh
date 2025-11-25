if [[ -z "$EDITOR" ]]; then
  for EDITOR in nvim vim nano; do
    if is_command "$EDITOR"; then
      export EDITOR
      export VISUAL="${VISUAL:-EDITOR}"
      break
    else
      unset EDITOR
    fi
  done
fi

export PAGER="${PAGER:-less}"
export LESS="--RAW-CONTROL-CHARS --tabs=4 --tilde --ignore-case --LONG-PROMPT"
if [[ -n "$NVIM" || -n "$VIM_TERMINAL" || -n "$TMUX" ]]; then LESS+=" --mouse --wheel-lines=5"; fi
export SYSTEMD_LESS="$LESS --quit-if-one-screen --chop-long-lines"
export MANPAGER="man-pager-with-tags"

export CLICOLOR=1

export LSCOLORS="Gxfxcxdxbxegedabagacad"  # BSD ls colors
export -T LS_COLORS ls_colors ':'  # GNU ls colors (tie this variable to a `:`-separated array

if is_command dircolors; then  # (this program is also part of GNU coreutils)
  # While not being a particularly complex task, executing `dircolors` still
  # requires forking to an external binary to essentially just get an unchanging
  # string of code to `eval`, and this is noticeable on systems where disk I/O
  # is expensive. Hence, it is better to cache the piece of code produced by
  # `dircolors` and regenerate it only when its binary gets updated together
  # with the rest of coreutils. Also note that the output of `dircolors` depends
  # on the value of $TERM and $COLORTERM, so they are a part of the cache key.
  cached_dircolors="${ZSH_CACHE_DIR}/dircolors-${TERM}-${COLORTERM}.sh"

  # Clear cached dircolors scripts every once in a while. The glob selects
  # regular files which were modified more than a week ago.
  for stale in "${ZSH_CACHE_DIR}/dircolors"*.sh(N.mw+0); do
    command rm -- "$stale";
  done; unset stale

  if should_rebuild "$cached_dircolors" "${commands[dircolors]}"; then
    command dircolors --bourne-shell >| "${cached_dircolors}.$$"
    command mv -f -- "${cached_dircolors}.$$" "$cached_dircolors"
  fi
  source "$cached_dircolors"
  unset cached_dircolors
fi

# lf can load settings from LS_COLORS, but the configuration which is generated
# by GNU dircolors contains some entries with reversed fg/bg colors, which looks
# super ugly in the actual UI of lf when such a file is selected. I include some
# overrides in the lf-specific LF_COLORS to fix types of files which suffer from
# this visual problem, and to match the color scheme between ranger and lf.
# <https://github.com/gokcehan/lf/blob/master/etc/colors.example>
# <https://github.com/gokcehan/lf/blob/c84e4456621481e1d1ae295a9dbc6e510e2ed049/colors.go>
# <https://github.com/ranger/ranger/blob/08913377c968d39f11fa2d546aa8d53a99bb5e98/ranger/colorschemes/default.py>
# <https://github.com/coreutils/coreutils/blob/b4e02e0ef4dd1a84f9a08e16612c7659caedbee5/src/dircolors.hin>
# <https://github.com/coreutils/coreutils/blob/b4e02e0ef4dd1a84f9a08e16612c7659caedbee5/src/dircolors.c#L53-L69>
export -T LF_COLORS lf_colors=(
  "fi=00"     # FILE
  "di=01;34"  # DIR
  "tw=01;34"  # STICKY_OTHER_WRITABLE
  "ow=01;34"  # OTHER_WRITABLE
  "st=01;34"  # STICKY
  "ln=01;36"  # LINK
  "or=31;01"  # ORPHAN
  "pi=33"     # FIFO
  "so=01;35"  # SOCK
  "bd=33;01"  # BLK
  "cd=33;01"  # CHR
  "ex=01;32"  # EXEC
  "su=01;32"  # SETUID
  "sg=01;32"  # SETGID
) ':'

# see COLORS in jq(1)
export -T JQ_COLORS jq_colors=(
  "0;38;5;16" # null
  "0;38;5;16" # false
  "0;38;5;16" # true
  "0;38;5;16" # numbers
  "0;32"      # strings
  "0;39"      # arrays
  "0;39"      # objects
) ':'

if is_command brew; then
  export HOMEBREW_NO_EMOJI=1
  export HOMEBREW_NO_AUTO_UPDATE=1
  export HOMEBREW_NO_INSTALL_UPGRADE=1
  export HOMEBREW_NO_INSTALL_CLEANUP=1
fi

export FZF_DEFAULT_OPTS="--height=40% --reverse --bind=change:first"
if is_command rg; then
  export FZF_DEFAULT_COMMAND="rg --files --hidden --follow --glob='!{.git,.svn,.hg,.DS_Store,*~}'"
fi

# <https://github.com/sharkdp/bat#8-bit-themes>
export BAT_THEME="base16-256"

# <https://foss.heptapod.net/pypy/pypy/-/blob/release-pypy3.7-v7.3.5/lib_pypy/_pypy_irc_topic.py>
# <https://foss.heptapod.net/pypy/pypy/-/blob/release-pypy3.7-v7.3.5/lib_pypy/_pypy_interact.py#L17-27>
# <https://foss.heptapod.net/pypy/pypy/-/blob/release-pypy3.7-v7.3.5/pypy/interpreter/app_main.py#L892-896>
export PYPY_IRC_TOPIC=1

if [[ ! -v KITTY_INSTALLATION_DIR ]]; then
  for KITTY_INSTALLATION_DIR in \
    ${commands[kitty]:+"${commands[kitty]:A:h:h}/lib/kitty"} \
    /usr/lib/kitty /usr/local/lib/kitty \
    "${XDG_DATA_HOME:-${HOME}/.local/share}/kitty-ssh-kitten"
  do
    if [[ -d "${KITTY_INSTALLATION_DIR}/shell-integration/zsh" ]]; then
      export KITTY_INSTALLATION_DIR
      break
    else
      unset KITTY_INSTALLATION_DIR
    fi
  done
fi

if [[ -v KITTY_INSTALLATION_DIR ]]; then
  export KITTY_SHELL_INTEGRATION="${KITTY_SHELL_INTEGRATION:-enabled}"
fi
