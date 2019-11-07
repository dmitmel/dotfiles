if !g:vim_ide | finish | endif

call coc#add_extension('coc-css')
let g:coc_filetypes += ['css', 'scss', 'less']
