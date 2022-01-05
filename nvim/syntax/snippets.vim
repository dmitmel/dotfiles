" Taken from <https://github.com/garbas/vim-snipmate/blob/ed3c5426a20bf1c06d7980946ada34fd9f93320e/syntax/snippets.vim>.

" Syntax highlighting for .snippets files (used for snipMate.vim)
" Hopefully this should make snippets a bit nicer to write!
syn match snipComment '^#.*'
syn match placeHolder '\${\d\+\(:.\{-}\)\=}' contains=snipCommand
syn match tabStop '\$\d\+'
syn match snipEscape '\\\\\|\\`'
syn match snipCommand '\%(\\\@<!\%(\\\\\)*\)\@<=`.\{-}\%(\\\@<!\%(\\\\\)*\)\@<=`'
syn match snippet '^snippet.*' contains=multiSnipText,snipKeyword
syn match snippet '^extends.*' contains=snipKeyword
syn match snippet '^version.*' contains=snipKeyword
syn match multiSnipText '\S\+ \zs.*' contained
syn match snipKeyword '^(snippet|extends|version)'me=s+8 contained
syn match snipError "^[^#vse\t].*$"

hi link snippet       Identifier
hi link snipComment   Comment
hi link multiSnipText String
hi link snipKeyword   Keyword
hi link snipEscape    SpecialChar
hi link placeHolder   Special
hi link tabStop       Special
hi link snipCommand   String
hi link snipError     Error
