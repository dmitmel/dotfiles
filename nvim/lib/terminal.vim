nnoremap <silent> <leader>t :terminal<CR>

augroup vimrc-terminal
  autocmd!
  autocmd TermOpen * set nocursorline | IndentLinesDisable
augroup END
