let s:filetypes = {'haskell': 1, 'lhaskell': 1, 'chaskell': 1}
call extend(g:dotfiles_coc_filetypes, s:filetypes)

let g:coc_user_config['languageserver.haskell'] = {
\ 'filetypes': keys(s:filetypes),
\ 'command': 'haskell-language-server-wrapper',
\ 'args': ['--lsp'],
\ 'rootPatterns': ['*.cabal', 'stack.yaml', 'cabal.project', 'package.yaml', 'hie.yaml'],
\ 'initializationOptions': {},
\ }
