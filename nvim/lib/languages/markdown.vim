let g:coc_filetypes += ['markdown']

let g:vim_markdown_conceal = 0
let g:vim_markdown_conceal_code_blocks = 0

augroup vimrc-languages-markdown
  autocmd!
  autocmd FileType markdown call pencil#init()
augroup END
