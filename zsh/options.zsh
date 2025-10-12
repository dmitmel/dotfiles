# http://zsh.sourceforge.net/Doc/Release/Options.html#Description-of-Options-1
# http://zsh.sourceforge.net/Doc/Release/Parameters.html#Parameters-Used-By-The-Shell

# remove some characters from the standard WORDCHARS
WORDCHARS="${WORDCHARS//[\/=]}"
# disable Ctrl+S and Ctrl+Q (https://unix.stackexchange.com/questions/137842/what-is-the-point-of-ctrl-s)
setopt no_flow_control

setopt correct_all

# recognize comments in the prompt
setopt interactive_comments

setopt extended_glob

# enable support for multiple redirections in one command
setopt multios
# disallow redirection to file (i.e. `>`) if the file already exists, this can
# be overriden by using `>!` or `>|` redirection operators
setopt no_clobber
# command to assume when redirection is used without a command
READNULLCMD=cat

setopt long_list_jobs

# if the first word in the command is a directory name, `cd` into it
setopt auto_cd
# automatically push directories onto the stack when doing a `cd`, but remove
# older duplicates (this works like history of a single tab in a web browser)
setopt auto_pushd pushd_ignore_dups

# do not autoselect the first completion entry
setopt no_menu_complete
# if the cursor is inside a word, use part from the beginning to the cursor as
# prefix and from the cursor to the end as suffix when searching for
# completions (the default behavior is to use the whole word as a substring)
setopt complete_in_word
# setopt always_to_end     # does this option affect anything?

# strangely enough, Zsh doesn't save command history by default
HISTFILE="${HISTFILE:-$HOME/.zsh_history}"
# max number of entries stored in memory
HISTSIZE=210000
# max number of entries in the HISTFILE
SAVEHIST=200000
# record timestamps in the history
setopt extended_history
# delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_expire_dups_first
# ignore duplicated history items
setopt hist_ignore_dups
# ignore commands that start with space
setopt hist_ignore_space
# don't run commands with history expansions immediately, instead allow the
# user to preview the expansions and edit the command after expansions in ZLE
setopt hist_verify
# immediately write HISTFILE to disk when a new command is appended
setopt inc_append_history
# synchronize history between active sessions
setopt share_history
