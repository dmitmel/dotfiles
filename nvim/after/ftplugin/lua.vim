" See also: <https://github.com/xolox/vim-lua-ftplugin>. (That plugin, however,
" is an overkill for us, plus we have LSP which provides real autocompletion
" and documentation popups).

exe dotutils#ftplugin_set('&comments', ':---,:--')

" Taken from <https://github.com/xolox/vim-lua-ftplugin/blob/bcbf914046684f19955f24664c1659b330fcb241/ftplugin/lua.vim#L21-L24>
exe dotutils#ftplugin_set('&include', '\v<%(%(do|load)file|require)>[^''"]*[''"]\zs[^''"]+')
exe dotutils#ftplugin_set('&includeexpr', 'dotfiles#ft#lua#includeexpr(v:fname)')
call dotutils#ftplugin_set('runfileprg', ':luafile %')

call dotutils#ftplugin_set('surround_'.char2nr('t'), "then \r end")
call dotutils#ftplugin_set('surround_'.char2nr('d'), "do \r end")
call dotutils#ftplugin_set('surround_'.char2nr('u'), "function() \r end")
call dotutils#ftplugin_set('surround_'.char2nr('i'), "if ... then \r end")
