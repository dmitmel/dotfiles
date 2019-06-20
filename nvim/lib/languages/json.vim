augroup vimrc-languages-json
  autocmd!
  autocmd FileType json syntax match Comment +\/\/.\+$+
augroup END

if !g:vim_ide | finish | endif

call coc#add_extension('coc-json')
let g:coc_filetypes += ['json']
