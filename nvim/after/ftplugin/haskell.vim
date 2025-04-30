" This was taken from <https://github.com/dag/vim2hs/blob/f2afd55704bfe0a2d66e6b270d247e9b8a7b1664/autoload/vim2hs/haskell/editing.vim#L2-L4>
let &l:include = '\v^\s*import%(\s+qualified)=\s+'
let &l:includeexpr = "tr(v:fname,'.','/')"
setlocal suffixesadd=hs,lhs,hsc,hsx

" <https://github.com/dag/vim2hs/blob/f2afd55704bfe0a2d66e6b270d247e9b8a7b1664/autoload/vim2hs/haskell/editing.vim#L105>
setlocal keywordprg=hoogle\ -i

let b:undo_ftplugin = get(b:, 'undo_ftplugin', '') . "\n" .
\ 'setlocal include< includeexpr< suffixesadd< keywordprg<'
