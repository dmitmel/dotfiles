#!/usr/bin/env bash
set -euo pipefail

# A helper script for `./autoload/dotfiles/nvim/sudo.vim`. It will be called by
# `sudo` as an askpass helper, with a prompt string as the only argument. In
# turn, it calls Neovim as a Vimscript interpreter and uses it to perform an RPC
# call back into a parent Neovim process. This is an extreme hack and I've done
# it this way to avoid reliance on other interpreters and third-party Neovim API
# client libraries (like pynvim) being installed on the system.

# An environment variable is an easiest method of passing a parameter to this
# inline Vimscript.
export prompt="${1-}"

# `-es` - run Neovim in script mode, without the TUI, read Ex commands over stdin
# `-u NONE` - skip vimrc and other initialization scripts
# `-i NONE` - don't load the ShaDa file
# `-n` - disables creation of swap files
# A pipe into `cat` at the end is necessary for sudo to read the password from
# the stdout of Vim for some mysterious reason which I don't want to debug.
"${NVIM_EXE:-nvim}" -u NONE -i NONE -n -es <<'VIM' | cat
try
  let address = empty($NVIM) ? $NVIM_LISTEN_ADDRESS : $NVIM
  let channel = sockconnect('pipe', address, { 'rpc': 1 })
  let input = rpcrequest(channel, 'nvim_call_function', 'dotfiles#nvim#sudo#askpass', [$prompt])
  call chanclose(channel)
  " Can't easily print something to stdout in the `-es` mode...
  call writefile(split(input, "\n"), '/dev/stdout', 'ab')
  cquit 0
catch
  verbose echo v:exception
  verbose echo "\n"
  cquit 1
endtry
VIM
