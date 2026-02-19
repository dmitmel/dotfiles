#!/usr/bin/env bash
set -euo pipefail

export prompt="${1-}"

"${NVIM_EXE:-nvim}" -u NONE -i NONE -n -es <<'VIM' | cat
try
  let address = empty($NVIM) ? $NVIM_LISTEN_ADDRESS : $NVIM
  let channel = sockconnect('pipe', address, { 'rpc': 1 })
  let input = rpcrequest(channel, 'nvim_call_function', 'dotfiles#nvim#sudo#askpass', [$prompt])
  call chanclose(channel)
  call writefile(split(input, "\n"), '/dev/stdout', 'ab')
  cquit 0
catch
  verbose echo v:exception
  verbose echo "\n"
  cquit 1
VIM
