source <sfile>:h/text.vim

exe dotfiles#ft#set('&makeprg', 'markdown2htmldoc -- %:S %:S.html')
call dotfiles#ft#set('runfileprg', ':Open %.html')

call dotfiles#ft#set('delimitMate_nesting_quotes', ['`'])

setlocal matchpairs-=<:>
call dotfiles#ft#undo_set('matchpairs')
