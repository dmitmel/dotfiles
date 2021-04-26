let g:coc_global_extensions += ['coc-pyright']
let g:coc_filetypes += ['python']

let s:ignored_errors = []
" Indent is not a multiple of 4
let s:ignored_errors += ['E111']
" Indent is not a multiple of 4 for comments
let s:ignored_errors += ['E114']
" Indent for continuation lines is smaller than expected
let s:ignored_errors += ['E121']
" Line too long
let s:ignored_errors += ['E501']

" let g:coc_user_config['pyls.plugins.pycodestyle.ignore'] = s:ignored_errors
" let g:coc_user_config['python.autocomplete.showAdvancedMembers'] = v:false
let g:coc_user_config['python'] = {
\ 'formatting': {
\   'provider': 'yapf',
\   'yapfArgs': ['--style=' . simplify(g:nvim_dotfiles_dir.'/../python/yapf.ini')]
\   },
\ 'linting': {
\   'pylintEnabled': v:false,
\   'flake8Enabled': v:true,
\   'flake8Args': ['--ignore=' . join(s:ignored_errors, ',')],
\   },
\ }
