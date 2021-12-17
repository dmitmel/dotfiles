" Helper file for the universal TODO comments system. It is used by files in
" `after/syntax/` to extend the built-in hlgroups to have somewhat unified
" lists of keywords.

" This rejected PEP has a semi-formal list of these markers: <https://www.python.org/dev/peps/pep-0350/#mnemonics>.
" "SAFETY" originates from Rust.
let g:dotfiles#todo_comments#keywords = ['TODO', 'NOTE', 'HACK', 'FIXME', 'XXX', 'BUG', 'SAFETY', 'WIP']

" The pattern idea was taken from <https://github.com/neovim/neovim/blob/v0.6.0/runtime/syntax/sh.vim#L396-L400>
" and <https://github.com/wbthomason/dotfiles/blob/9134e87b00102cda07f875805f900775244067fe/neovim/.config/nvim/init.lua#L88>.
function! dotfiles#todo_comments#get_pattern() abort
  let pat = '\V\C\<\%(' . join(map(g:dotfiles#todo_comments#keywords, { _, s -> escape(s, '\') }), '\|') . '\)\ze:\=\>'
  let wrap_char = '/'
  return wrap_char . escape(pat, wrap_char) . wrap_char
endfunction
