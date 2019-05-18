augroup vimrc-terminal
  autocmd!
  autocmd TermOpen  * setlocal nocursorline | IndentLinesDisable
  autocmd TermClose * setlocal   cursorline
augroup END
