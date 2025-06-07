" This file will be sourced by `runtime! ftplugin/man.vim` when loading the
" `man.vim` plugin in Vim, so beware of that. What a horrible way of
" initializing a plugin!
if &filetype ==# "man" && &buftype ==# 'nofile'
  " Customizations for the manpage viewer.
  " <https://github.com/neovim/neovim/blob/v0.11.1/runtime/lua/man.lua#L397-L405>
  setlocal bufhidden=delete
endif
