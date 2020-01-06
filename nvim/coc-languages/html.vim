let g:coc_global_extensions += ['coc-html', 'coc-emmet']
let s:emmet_filetype_mapping = { 'jinja': 'html' }
let g:coc_filetypes += ['html'] + keys(s:emmet_filetype_mapping)
let g:coc_user_config['emmet.includeLanguages'] = s:emmet_filetype_mapping
