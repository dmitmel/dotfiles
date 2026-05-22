if exists('b:did_indent')
  finish
endif
let b:did_indent = 1

" This is basically enough for Lisp-alikes?
" <https://github.com/neovim/neovim/blob/v0.12.2/runtime/indent/lisp.vim>
exe dotfiles#ft#setlocal('autoindent')
exe dotfiles#ft#setlocal('nosmartindent')
