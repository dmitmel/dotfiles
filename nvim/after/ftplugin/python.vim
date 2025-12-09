call dotfiles#ft#set('delimitMate_nesting_quotes', ['"', "'"])
call dotfiles#ft#set('runfileprg', 'python -- %')

" Allow shifting lines that start with `#`.
" <https://www.reddit.com/r/vim/comments/r70y6i/comment/hmz1exi/>
setlocal cinoptions-=#0
setlocal cinoptions+=#1
call dotfiles#ft#undo_set('&cinoptions')
