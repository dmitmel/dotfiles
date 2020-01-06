let g:coc_global_extensions += ['coc-python']
let g:coc_filetypes += ['python']
let g:coc_user_config['pyls.plugins.pycodestyle.ignore'] = ['E501']
let g:coc_user_config['python'] = {
\ 'autocomplete': { 'showAdvancedMembers': v:false },
\ 'formatting': { 'provider': 'black' },
\ 'linting': {
\   'pylintEnabled': v:false,
\   'flake8Enabled': v:true,
\   'flake8Args': ['--ignore', 'E501'],
\   },
\ }
