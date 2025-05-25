setlocal matchpairs-=<:>
call dotfiles#ft#undo_set('&matchpairs')
call dotfiles#ft#set('runfileprg', 'node -- %')
