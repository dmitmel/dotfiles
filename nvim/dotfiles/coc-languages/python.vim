call dotutils#add_unique(g:coc_global_extensions, 'coc-pyright')
call dotutils#add_unique(g:coc_global_extensions, '@yaegassy/coc-ruff')

let g:coc_user_config['python.formatting.yapfArgs'] = ['--style=' . g:dotfiles_dir.'/misc/yapf.ini']
let g:coc_user_config['python.linting.flake8Args'] = ['--config=' . g:dotfiles_dir.'/misc/flake8.ini']

let g:coc_user_config['ruff.configuration'] = g:dotfiles_dir.'/ruff.toml'
let g:coc_user_config['ruff.configurationPreference'] = 'filesystemFirst'
