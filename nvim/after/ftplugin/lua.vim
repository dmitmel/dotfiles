" See also: <https://github.com/xolox/vim-lua-ftplugin>. (That plugin, however,
" is an overkill for us, plus we have LSP which provides real autocompletion
" and documentation popups).

exe dotfiles#ft#setlocal('comments=:---,:--')

" <https://github.com/neovim/neovim/commit/2b0f967b7704dcc782aebc99ec79482c20b5feef>
" <https://github.com/neovim/neovim/commit/08c328b8b079334e7fb38472339c4f8ba1a0df3b>
if !has('nvim-0.11.0')
  " Taken from <https://github.com/xolox/vim-lua-ftplugin/blob/bcbf914046684f19955f24664c1659b330fcb241/ftplugin/lua.vim#L21-L24>
  exe dotfiles#ft#setlocal('include=\v<%(%(do|load)file|require)>[^''"]*[''"]\zs[^''"]+')
  exe dotfiles#ft#setlocal('includeexpr=dotfiles#ft#lua#includeexpr(v:fname)')
endif

call dotfiles#ft#set('runfileprg', ':luafile %')

call dotfiles#ft#set('surround_'.char2nr('t'), "then \r end")
call dotfiles#ft#set('surround_'.char2nr('d'), "do \r end")
call dotfiles#ft#set('surround_'.char2nr('u'), "function() \r end")
call dotfiles#ft#set('surround_'.char2nr('i'), "if ... then \r end")
