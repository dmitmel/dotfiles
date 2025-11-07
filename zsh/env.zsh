# find editor
export EDITOR="nvim"
export VISUAL="$EDITOR"

export PAGER='less'
export LESS='--RAW-CONTROL-CHARS'
# Removed K and X from the default value. See the journalctl(1) manpage.
export SYSTEMD_LESS='FRSM'

if [[ -n "$NVIM" || -n "$VIM_TERMINAL" || -n "$TMUX" ]]; then
  export LESS="$LESS --mouse --wheel-lines=5"
fi

export CLICOLOR=1

export LSCOLORS="Gxfxcxdxbxegedabagacad"  # BSD ls colors
export -T LS_COLORS ls_colors             # GNU ls colors
if is_command dircolors; then   # (this program is also part of GNU coreutils)
  # While not being a particularly complex task, executing `dircolors` still
  # requires forking to an external binary to essentially just get an unchanging
  # string of code to `eval`, and this is noticeable on systems where disk I/O
  # is expensive. Hence, it is better to cache the piece of code produced by
  # `dircolors` and regenerate it only when its binary gets updated together
  # with the rest of coreutils.
  cached_dircolors="${ZSH_CACHE_DIR}/dircolors.sh"
  if should_rebuild "$cached_dircolors" "${commands[dircolors]}"; then
    command dircolors --bourne-shell >| "${cached_dircolors}.$$"
    command mv -f -- "${cached_dircolors}.$$" "$cached_dircolors"
  fi
  source "$cached_dircolors"
  unset cached_dircolors
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

export HOMEBREW_NO_EMOJI=1
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_INSTALL_UPGRADE=1
export HOMEBREW_NO_INSTALL_CLEANUP=1

# https://github.com/junegunn/fzf/blob/764316a53d0eb60b315f0bbcd513de58ed57a876/src/tui/tui.go#L496-L515
export FZF_DEFAULT_OPTS="--color=16 --height=40% --reverse --bind=change:first"

# <https://github.com/sharkdp/bat#8-bit-themes>
export BAT_THEME="base16-256"

# <https://foss.heptapod.net/pypy/pypy/-/blob/release-pypy3.7-v7.3.5/lib_pypy/_pypy_irc_topic.py>
# <https://foss.heptapod.net/pypy/pypy/-/blob/release-pypy3.7-v7.3.5/lib_pypy/_pypy_interact.py#L17-27>
# <https://foss.heptapod.net/pypy/pypy/-/blob/release-pypy3.7-v7.3.5/pypy/interpreter/app_main.py#L892-896>
export PYPY_IRC_TOPIC=1

if [[ -z "$KITTY_INSTALLATION_DIR" && -d /usr/lib/kitty/shell-integration/zsh ]]; then
  export KITTY_INSTALLATION_DIR="/usr/lib/kitty"
  export KITTY_SHELL_INTEGRATION="${KITTY_SHELL_INTEGRATION:-enabled}"
fi
