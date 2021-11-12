source <sfile>:h/text.vim

let &l:makeprg = 'markdown2htmldoc -- %:S %:S.html'
nnoremap <buffer> <F5> <Cmd>Open %.html<CR>

let b:delimitMate_nesting_quotes = ['`']

call dotfiles#utils#undo_ftplugin_hook('setlocal makeprg< | exe "silent! nunmap <buffer> <F5>" | unlet! b:delimitMate_nesting_quotes')
