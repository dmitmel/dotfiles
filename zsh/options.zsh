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
# if the cursor is inside a word, use the part from the beginning to the cursor
# as prefix and from the cursor to the end as suffix when searching for
# completions (the default behavior is to use the whole word as a substring)
setopt complete_in_word

# record timestamps in the history file
setopt extended_history
# append entries to the HISTFILE immediately after a command gets entered, and
# synchronize the history between active Zsh sessions
setopt share_history hist_fcntl_lock
# delete duplicates first when HISTFILE size exceeds HISTSIZE (unrelated to hist_ignore_dups!)
setopt hist_expire_dups_first
# don't add a command to the history if it is the same as the command entered
# right before it (like, if you press <Up> and <Enter>)
setopt hist_ignore_dups
# ignore commands that start with a space character (sort of an incognito mode for the shell)
setopt hist_ignore_space
# trim ALL unnecessary whitespace from commands saved to the history
setopt hist_reduce_blanks
# if a command was entered that includes a history expansion (`!!`, `!$` etc),
# don't run it immediately, instead, allow the user to preview the expanded
# result and edit the command if necessary
setopt hist_verify

# max number of entries stored in memory
HISTSIZE=1000000
# max number of entries in the HISTFILE
SAVEHIST=1000000
# set the history file only AFTER all of the history-related options have been
# configured to avoid corrupting it
HISTFILE="${HOME}/.zsh_history"
