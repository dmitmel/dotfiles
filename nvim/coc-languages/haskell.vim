let s:filetypes = {'haskell': 1, 'lhaskell': 1, 'chaskell': 1}
call extend(g:dotfiles_coc_filetypes, s:filetypes)

let g:coc_user_config['languageserver.haskell'] = {
\ 'filetypes': keys(s:filetypes),
\ 'command': 'hie-wrapper',
\ 'rootPatterns': ['.stack.yaml', 'cabal.config', 'package.yaml'],
\ 'initializationOptions': {},
\ }
