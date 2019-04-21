call coc#add_extension('coc-rls')
let g:coc_filetypes += ['rust']
call coc#config('rust', { 'clippy_preference': 'on' })

let g:rust_recommended_style = 0

augroup vimrc-rust
  autocmd FileType rust setlocal matchpairs-=<:>
augroup END
