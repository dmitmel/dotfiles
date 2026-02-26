exe dotfiles#ft#setlocal('wrap')
exe dotfiles#ft#setlocal('textwidth=0')
exe dotfiles#ft#setlocal('colorcolumn=')
exe dotfiles#ft#setlocal('showbreak=' . (has('nvim-0.6.0') ? 'NONE' : ''))

call dotfiles#ft#set('indentLine_enabled', 0)

" Insert undo breaks after punctuation characters, taken from
" <https://github.com/preservim/vim-pencil/blob/6d70438a8886eaf933c38a7a43a61adb0a7815ed/autoload/pencil.vim#L448-L453>
for s:key in ['.', '!', '?', ',', ';', ':']
  exe 'inoremap <buffer>' s:key s:key.'<C-g>u'
  call dotfiles#ft#undo_map('i', s:key)
endfor
