let g:coc_user_config['languageserver.haskell'] = {
\ 'filetypes': ['haskell', 'lhaskell', 'chaskell'],
\ 'command': 'haskell-language-server-wrapper',
\ 'args': ['--lsp'],
\ 'rootPatterns': ['*.cabal', 'stack.yaml', 'cabal.project', 'package.yaml', 'hie.yaml'],
\ 'initializationOptions': {},
\ }
