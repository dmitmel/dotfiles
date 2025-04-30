source <sfile>:h/text.vim

let &l:makeprg = 'markdown2htmldoc -- %:S %:S.html'
let b:runfileprg = ':Open %.html'

let b:delimitMate_nesting_quotes = ['`']
setlocal matchpairs-=<:>

let b:undo_ftplugin = get(b:, 'undo_ftplugin', '') . "\n" .
\ 'setlocal makeprg< matchpairs< | unlet! b:runfileprg b:delimitMate_nesting_quotes'
