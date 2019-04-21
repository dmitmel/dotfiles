call coc#add_extension('coc-python')
let g:coc_filetypes += ['python']
call coc#config('pyls.plugins.pycodestyle.ignore', ['E501'])
call coc#config('python', {
\ 'autocomplete': { 'showAdvancedMembers': v:false },
\ 'formatting': { 'provider': 'black' },
\ 'linting': {
\   'pylintEnabled': v:false,
\   'flake8Enabled': v:true,
\   'flake8Args': ['--ignore', 'E501'],
\   },
\ })

augroup vimrc-language-python
  autocmd!
  autocmd FileType python Indent 4
augroup END

let g:python_highlight_all = 1
