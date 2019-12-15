let g:rust_recommended_style = 0

if !g:vim_ide | finish | endif

call coc#add_extension('coc-rls')
let g:coc_filetypes += ['rust']
call coc#config('rust', { 'clippy_preference': 'on' })
