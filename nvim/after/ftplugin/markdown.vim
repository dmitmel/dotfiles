source <sfile>:h/text.vim

let &l:makeprg = 'markdown2htmldoc -- %:S %:S.html'

nnoremap <buffer> <F5> <Cmd>Open %.html<CR>
