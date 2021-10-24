" See also: <https://github.com/xolox/vim-lua-ftplugin>. (That plugin, however,
" is an overkill for us, plus we have LSP which provides real autocompletion
" and documentation popups).

nnoremap <buffer> <F5> <Cmd>luafile %<CR>

setlocal comments=:---,:--

" Taken from <https://github.com/xolox/vim-lua-ftplugin/blob/bcbf914046684f19955f24664c1659b330fcb241/ftplugin/lua.vim#L21-L24>
let &l:include = '\v<%(%(do|load)file|require)>[^''"]*[''"]\zs[^''"]+'
let &l:includeexpr = 'dotfiles#ftplugin_lua#includeexpr(v:fname)'

call dotfiles#utils#undo_ftplugin_hook('exe "silent! nunmap <buffer> <F5>" | setlocal comments< include< includeexpr<')
