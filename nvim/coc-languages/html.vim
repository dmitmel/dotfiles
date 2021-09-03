call extend(g:dotfiles_coc_extensions, {'coc-html': 1, 'coc-emmet': 1, 'coc-prettier': 1})
let s:emmet_filetype_mapping = { 'jinja': 'html' }
call extend(g:dotfiles_coc_filetypes, {'html': 1})
call extend(g:dotfiles_coc_filetypes, map(copy(s:emmet_filetype_mapping), {k, v -> 1}))

let g:coc_user_config['emmet.includeLanguages'] = s:emmet_filetype_mapping
