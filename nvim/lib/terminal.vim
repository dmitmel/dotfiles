nnoremap <silent> <leader>t :terminal<CR>

augroup vimrc-terminal
  autocmd!
  autocmd TermOpen * setl nocursorline | IndentLinesDisable
augroup END
