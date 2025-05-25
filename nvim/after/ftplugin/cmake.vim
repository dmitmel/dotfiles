setlocal iskeyword+=-
call dotfiles#ft#undo_set('&iskeyword')
exe dotfiles#ft#set('&comments', ':#')
exe dotfiles#ft#set('&commentstring', '#%s')
