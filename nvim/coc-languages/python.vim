let g:dotfiles_coc_extensions += ['coc-pyright']
let g:coc_filetypes += ['python']

let g:coc_user_config['python'] = {
\ 'formatting': {
\   'provider': 'yapf',
\   'yapfArgs': ['--style=' . g:dotfiles_dir.'/python/yapf.ini'],
\   },
\ 'linting': {
\   'pylintEnabled': v:false,
\   'flake8Enabled': v:true,
\   'flake8Args': ['--config=' . g:dotfiles_dir.'/python/flake8.ini'],
\   },
\ 'analysis': {
\   'typeCheckingMode': 'strict',
\   },
\ }
