setlocal comments&vim
call dotfiles#ft#undo_set('&comments')
exe dotfiles#ft#set('&commentstring', '//%s')
