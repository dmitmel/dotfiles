function! airline#extensions#dotfiles_tweaks#init(ext) abort
  " Undo this commit a little bit:
  " <https://github.com/vim-airline/vim-airline/commit/8929bc72a13d358bb8369443386ac3cc4796ca16>
  call airline#parts#define('maxlinenr', {
  \ 'raw': trim(airline#parts#get('maxlinenr').raw),
  \ })
  call airline#parts#define('colnr', {
  \ 'raw': trim(airline#parts#get('colnr').raw),
  \ 'accent': 'none',
  \ })
endfunction
