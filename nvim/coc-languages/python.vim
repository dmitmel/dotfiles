let g:coc_global_extensions += ['coc-pyright']
let g:coc_filetypes += ['python']

" let g:coc_user_config['python.autocomplete.showAdvancedMembers'] = v:false
let g:coc_user_config['python'] = {
\ 'formatting': {
\   'provider': 'yapf',
\   'yapfArgs': ['--style=' . simplify(g:dotfiles_dir.'/python/yapf.ini')]
\   },
\ 'linting': {
\   'pylintEnabled': v:false,
\   'flake8Enabled': v:true,
\   'flake8Args': ['--config=' . simplify(g:dotfiles_dir.'/python/flake8.ini')],
\   },
\ }
