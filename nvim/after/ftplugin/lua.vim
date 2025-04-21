" See also: <https://github.com/xolox/vim-lua-ftplugin>. (That plugin, however,
" is an overkill for us, plus we have LSP which provides real autocompletion
" and documentation popups).

let b:runfileprg = ':luafile %'

setlocal comments=:---,:--

" Taken from <https://github.com/xolox/vim-lua-ftplugin/blob/bcbf914046684f19955f24664c1659b330fcb241/ftplugin/lua.vim#L21-L24>
let &l:include = '\v<%(%(do|load)file|require)>[^''"]*[''"]\zs[^''"]+'
let &l:includeexpr = 'dotfiles#ft#lua#includeexpr(v:fname)'

call dotutils#undo_ftplugin_hook('unlet! b:runfileprg | setlocal comments< include< includeexpr<')
