if !g:vim_ide | finish | endif

call coc#add_extension('coc-html', 'coc-emmet')
let g:coc_filetypes += ['html']
