augroup vimrc-languages-text
  autocmd!
  autocmd FileType text call pencil#init()
augroup END

if !g:vim_ide | finish | endif
