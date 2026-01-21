# this alias removes leading dollar sign (useful when copying code from Stackoverflow)
alias '$'=''

# the following aliases allow alias expansion in common programs which take
# commands as their arguments
alias sudo='sudo '
alias watch='watch '
alias xargs='xargs '
alias nice='nice '

alias history='fc -i -l 1'

alias dirs='dirs -v'

alias grep='grep --color=auto'
alias diff='diff --color=auto --unified'

alias sudoe="sudoedit"
alias sue="sudoedit"

if is_command dmesg; then
  # `--human` makes `dmesg` display timestamps in the logs in a more
  # human-readable way, and also start the pager automatically
  alias dmesg='dmesg --human'
  # use `sudo` if the current user is not root
  if (( EUID != 0 )); then
    # Purposefully defined as a function, not an alias, to call `sudo` only if
    # this command was not invoked with `sudo` in the first place.
    dmesg() { sudo dmesg "$@"; }
  fi
fi

if command_exists eza; then
  alias ls="eza --classify --group-directories-first"
  alias l="${aliases[ls]} --long --header --binary --group"
  alias la="${aliases[l]} --all"
  alias lt="${aliases[l]} --tree"
  alias lat="${aliases[la]} --tree"
  alias tree="${aliases[ls]} --tree"
else
  alias ls="ls --classify --group-directories-first --color=auto"
  alias l="${aliases[ls]} -l --human-readable"
  alias la="${aliases[l]} --almost-all"
fi

# fd is a simple, fast and user-friendly alternative to find - https://github.com/sharkdp/fd
if command_exists fd; then
  alias fda='fd --hidden --no-ignore'
fi

# some amendments to Oh My Zsh's git plugin
# https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/git/git.plugin.zsh
alias glo="git log --decorate --abbrev-commit --date=relative --pretty='%C(auto)%h%C(reset)%C(auto)%d%C(reset) %s %C(green)- %an %C(blue)(%ad)%C(reset)'"
alias glog="${aliases[glo]} --graph"
alias gloga="${aliases[glog]} --all"

# git with hub
if command_exists hub; then
  alias git='hub'
  alias gw='git browse'
  alias gci='git ci-status --verbose'
else
  alias gw='gh browse'
  alias ghcl='gh repo clone'
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

alias ip='ip -color=auto -human-readable'

if command_exists apt && command_exists apt-get; then
  apt_get_message="use 'apt' instead of 'apt-get'
if you really want to use 'apt-get', type '\\apt-get'"
  alias apt-get="echo -E ${(q-)apt_get_message} #"
  unset apt_get_message
fi

# editor
alias edit="$EDITOR"
alias e="$EDITOR"
if [[ "$EDITOR" == *vim ]]; then
  alias es="$EDITOR -S"
fi

# -a = --archive
# -A = --acls
# -X = --xattrs
# -H = --hard-links
# -z = --compress
# -P = --partial --progress
# -v = --verbose
# -h = --human-readable
alias rsync-backup='rsync -aAXHzPvh --info=progress2'

if command_exists ncdu; then
  alias ncdu='ncdu --confirm-quit'
fi

alias bin-disassemble='objdump --disassemble --disassembler-options=intel --source --demangle'
alias bin-dump='objdump --disassemble --disassembler-options=intel --full-contents --all-headers'
alias bin-list-symbols='nm --demangle'
alias bin-dylib-symbols='nm --dynamic --extern-only --demangle'

if [[ -f /proc/driver/nvidia/version ]]; then
  # Duplicated as an alias to prevent autocorrection of the real "command" part.
  # See also scripts/prime-run
  alias prime-run='__NV_PRIME_RENDER_OFFLOAD=1 __VK_LAYER_NV_optimus=NVIDIA_only __GLX_VENDOR_LIBRARY_NAME=nvidia '
else
  alias prime-run=''
fi

if ! command_exists update-grub; then
  # Doesn't exist on Arch by default. Probably implementing this command was
  # left as a challenge to the documentation reader.
  alias update-grub="grub-mkconfig -o /boot/grub/grub.cfg"
fi

alias bytefmt2="numfmt --to=iec-i --suffix=B"
alias bytefmt10="numfmt --to=si --suffix=B"

if command_exists dragon-drop && ! command_exists dragon; then
  alias dragon='dragon-drop'
fi

alias gtime="command time -v"

alias yarn="yarn --emoji false"

# <https://mpv.io/manual/stable/#pseudo-gui-mode>
alias mpv='mpv --player-operation-mode=pseudo-gui'

alias gdb='DOTFILES_GDB_DASHBOARD=1 gdb'

if [[ "${commands[man]:A}" == "${commands[mandoc]:A}" ]]; then
  alias man='man -O width="$((COLUMNS - 1))"'
else
  # Search for some string in all man pages
  alias mangrep='man -wK'
fi
