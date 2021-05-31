function! airline#extensions#dotfiles_tweaks#init(ext) abort
  " Undo this commit a little bit:
  " <https://github.com/vim-airline/vim-airline/commit/8929bc72a13d358bb8369443386ac3cc4796ca16>
  " Most of the hacks present here are not required anymore:
  " <https://github.com/vim-airline/vim-airline/commit/1f94ec1556db36088897c85db62251b62b683ab3>
  call airline#parts#define_accent('colnr', 'none')
endfunction
