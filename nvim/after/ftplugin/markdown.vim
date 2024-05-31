source <sfile>:h/text.vim

let &l:makeprg = 'markdown2htmldoc -- %:S %:S.html'
let b:runfileprg = ':Open %.html'

let b:delimitMate_nesting_quotes = ['`']
setlocal matchpairs-=<:>

call dotfiles#utils#undo_ftplugin_hook('setlocal makeprg< matchpairs< | unlet! b:runfileprg b:delimitMate_nesting_quotes')
