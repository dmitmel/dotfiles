if !g:vim_ide | finish | endif

call coc#add_extension('coc-html', 'coc-emmet')
let s:emmet_filetype_mapping = { 'jinja': 'html' }
let g:coc_filetypes += ['html'] + keys(s:emmet_filetype_mapping)
call coc#config('emmet.includeLanguages', s:emmet_filetype_mapping)
