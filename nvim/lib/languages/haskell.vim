let s:filetypes = ['haskell', 'lhaskell', 'chaskell']
let g:coc_filetypes += s:filetypes
call coc#config('languageserver.haskell', {
\ 'filetypes': s:filetypes,
\ 'command': 'hie-wrapper',
\ 'rootPatterns': ['.stack.yaml', 'cabal.config', 'package.yaml'],
\ 'initializationOptions': {},
\ })

let g:haskell_conceal = 0
let g:haskell_conceal_enumerations = 0
let g:haskell_multiline_strings = 1
