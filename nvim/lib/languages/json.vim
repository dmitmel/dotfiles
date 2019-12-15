if !g:vim_ide | finish | endif

call coc#add_extension('coc-json')
let g:coc_filetypes += ['json', 'json5']
