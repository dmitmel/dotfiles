call dotutils#add_unique(g:coc_global_extensions, 'coc-pyright')

let g:coc_user_config['python.formatting'] = {
\ 'yapfArgs': ['--style=' . g:dotfiles_dir.'/misc/yapf.ini'],
\ 'ruffArgs': ['--config=' . g:dotfiles_dir.'/misc/ruff.toml', '--no-cache'],
\}

let g:coc_user_config['python.linting'] = {
\ 'flake8Args': ['--config=' . g:dotfiles_dir.'/misc/flake8.ini'],
\ 'ruffArgs':   ['--config=' . g:dotfiles_dir.'/misc/ruff.toml', '--no-cache'],
\}
