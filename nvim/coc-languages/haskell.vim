let s:filetypes = ['haskell', 'lhaskell', 'chaskell']
let g:coc_filetypes += s:filetypes
call coc#config('languageserver.haskell', {
\ 'filetypes': s:filetypes,
\ 'command': 'hie-wrapper',
\ 'rootPatterns': ['.stack.yaml', 'cabal.config', 'package.yaml'],
\ 'initializationOptions': {},
\ })
