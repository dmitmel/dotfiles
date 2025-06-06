call pencil#init()

" <https://github.com/preservim/vim-pencil/blob/6d70438a8886eaf933c38a7a43a61adb0a7815ed/autoload/pencil.vim#L426-L428>
silent! iunmap <buffer> <Up>
silent! iunmap <buffer> <Down>

call dotfiles#ft#set('indentLine_enabled', 0)

if exists('+smoothscroll')
  exe dotfiles#ft#set('&smoothscroll', 1)
endif
