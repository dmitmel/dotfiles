" See also: <https://github.com/xolox/vim-lua-ftplugin>. (That plugin, however,
" is an overkill for us, plus we have LSP which provides real autocompletion
" and documentation popups).

exe dotfiles#ft#set('&comments', ':---,:--')

" Taken from <https://github.com/xolox/vim-lua-ftplugin/blob/bcbf914046684f19955f24664c1659b330fcb241/ftplugin/lua.vim#L21-L24>
exe dotfiles#ft#set('&include', '\v<%(%(do|load)file|require)>[^''"]*[''"]\zs[^''"]+')
exe dotfiles#ft#set('&includeexpr', 'dotfiles#ft#lua#includeexpr(v:fname)')
call dotfiles#ft#set('runfileprg', ':luafile %')

call dotfiles#ft#set('surround_'.char2nr('t'), "then \r end")
call dotfiles#ft#set('surround_'.char2nr('d'), "do \r end")
call dotfiles#ft#set('surround_'.char2nr('u'), "function() \r end")
call dotfiles#ft#set('surround_'.char2nr('i'), "if ... then \r end")
