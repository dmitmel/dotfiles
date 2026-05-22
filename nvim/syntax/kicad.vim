" <https://dev-docs.kicad.org/en/file-formats/sexpr-intro/index.html>
" <https://gitlab.com/kicad/code/kicad/-/blob/master/libs/sexpr/sexpr_parser.cpp>

if exists('b:current_syntax')
  finish
endif

let s:cpo_save = &cpoptions
set cpoptions&vim

" Must come first so that it gets the lowest priority when actually matching.
" The name "symbol" comes from how these are named in Kicad's code. Basically
" any sequence of non-whitespace characters and parens is considered a valid
" symbol: <https://gitlab.com/kicad/code/kicad/-/blob/10.0.3/libs/sexpr/sexpr_parser.cpp#L171-174>
syntax match kicadSymbol /[^ \x08-\x0d()]\+/

syntax region kicadList transparent matchgroup=kicadParen start="(" end=")"

" A token is basically a list with a name. `lc=1` makes Vim's syntax engine step
" a single character back before trying to match this pattern, therefore making
" it possible to match it after an opening paren has already been consumed by
" `kicadList`.
syntax match kicadToken /([ \x08-\x0d]*\w\+[^ \x08-\x0d())]\@!/lc=1

syntax region kicadString start=/"/ skip=/\\\\\|\\"/ end=/"/ contains=kicadEscaped
syntax match kicadEscaped /\\\_./ contained

" From the standpoint of the parser, a number is any sequence of digits and
" dots, optionally preceded by a minus: <https://gitlab.com/kicad/code/kicad/-/blob/10.0.3/libs/sexpr/sexpr_parser.cpp#L179-181>
" It doesn't give any errors if it doesn't actually look like a number, and it
" will happily try to parse garbage like `-.` or `1.2.3` or even a lone dot as
" a floating-point number.
syntax match kicadNumber /[^ \x08-\x0d()]\@1<!-\?[[:digit:].]\+[^ \x08-\x0d())]\@!/

highlight default link kicadParen   Delimiter
highlight default link kicadString  String
highlight default link kicadEscaped Special
highlight default link kicadNumber  Number
highlight default link kicadToken   Identifier
highlight default link kicadSymbol  Special

let b:current_syntax = 'kicad'

let &cpoptions = s:cpo_save
unlet s:cpo_save
