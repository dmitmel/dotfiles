call coc#add_extension('coc-rls')
let g:coc_filetypes += ['rust']
call coc#config('rust', { 'clippy_preference': 'on' })
