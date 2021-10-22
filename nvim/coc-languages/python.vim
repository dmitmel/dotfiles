call extend(g:dotfiles_coc_extensions, {'coc-pyright': 1})
call extend(g:dotfiles_coc_filetypes, {'python': 1})

let g:coc_user_config['python'] = {
\ 'formatting': {
\   'provider': 'yapf',
\   'yapfArgs': ['--style=' . g:dotfiles_dir.'/misc/yapf.ini'],
\   },
\ 'linting': {
\   'pylintEnabled': v:false,
\   'flake8Enabled': v:true,
\   'flake8Args': ['--config=' . g:dotfiles_dir.'/misc/flake8.ini'],
\   },
\ 'analysis': {
\   'typeCheckingMode': 'strict',
\   },
\ }
