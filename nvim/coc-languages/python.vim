call extend(g:dotfiles_coc_extensions, {'coc-pyright': 1})
call extend(g:dotfiles_coc_filetypes, {'python': 1})

let g:coc_user_config['python'] = {
\ 'formatting': {
\   'provider': 'ruff',
\   'yapfArgs': ['--style=' . g:dotfiles_dir.'/misc/yapf.ini'],
\   'ruffArgs': ['--config=' . g:dotfiles_dir.'/misc/ruff.toml', '--no-cache'],
\   },
\ 'linting': {
\   'pylintEnabled': v:false,
\   'flake8Enabled': v:false,
\   'flake8Args': ['--config=' . g:dotfiles_dir.'/misc/flake8.ini'],
\   'ruffEnabled': v:true,
\   'ruffArgs': ['--config=' . g:dotfiles_dir.'/misc/ruff.toml', '--no-cache'],
\   },
\ 'analysis': {
\   'autoSearchPaths': v:true,
\   'useLibraryCodeForTypes': v:true,
\   'diagnosticMode': 'workspace',
"\   'typeCheckingMode': 'strict',
\   },
\ }

let g:coc_user_config['pyright'] = {
\  'inlayHints': {
\     'functionReturnTypes': v:false,
\     'variableTypes': v:false,
\     'parameterTypes': v:false,
\   }
\ }
