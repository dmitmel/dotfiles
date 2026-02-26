call dotfiles#ft#set('delimitMate_nesting_quotes', ['"', "'"])
call dotfiles#ft#set('runfileprg', 'python -- %')

" Allow shifting lines that start with `#`.
" <https://www.reddit.com/r/vim/comments/r70y6i/comment/hmz1exi/>
exe dotfiles#ft#setlocal('cinoptions-=#0')
exe dotfiles#ft#setlocal('cinoptions+=#1')

if exists('loaded_matchit') && !exists('b:match_skip')
  call dotfiles#ft#set('match_skip', 's:string\|comment\|bytes')
endif

call dotfiles#ft#set('surround_'.char2nr('i'), "if ...:\r")
call dotfiles#ft#set('surround_'.char2nr('I'), "elif ...:\r")
call dotfiles#ft#set('surround_'.char2nr('e'), "else:\r")
call dotfiles#ft#set('surround_'.char2nr('w'), "with ...:\r")
call dotfiles#ft#set('surround_'.char2nr('t'), "try:\r\nexcept:\n pass")
