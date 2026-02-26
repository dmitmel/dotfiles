" This was taken from <https://github.com/dag/vim2hs/blob/f2afd55704bfe0a2d66e6b270d247e9b8a7b1664/autoload/vim2hs/haskell/editing.vim#L2-L4>
exe dotfiles#ft#setlocal('include=\v^\s*import%(\s+qualified)=\s+')
exe dotfiles#ft#setlocal("includeexpr=tr(v:fname,'.','/')")
exe dotfiles#ft#setlocal('suffixesadd=hs,lhs,hsc,hsx')
" <https://github.com/dag/vim2hs/blob/f2afd55704bfe0a2d66e6b270d247e9b8a7b1664/autoload/vim2hs/haskell/editing.vim#L105>
exe dotfiles#ft#setlocal('keywordprg=hoogle -i')
