" <https://dev-docs.kicad.org/en/file-formats/sexpr-intro/index.html>
" <https://gitlab.com/kicad/code/kicad/-/blob/master/common/dsnlexer.cpp>
" <https://gitlab.com/kicad/code/kicad/-/blob/master/common/dsnlexer.h>

if exists('b:current_syntax')
  finish
endif

let s:cpo_save = &cpoptions
set cpoptions&vim

" Must come first so that it gets the lowest priority when actually matching.
" The name "symbol" comes from how these are named in Kicad's code. Basically,
" any sequence of non-whitespace characters and parens is considered a valid
" symbol: <https://gitlab.com/kicad/code/kicad/-/blob/10.0.3/common/dsnlexer.cpp#L808-813>
syntax match kicadSymbol /[^ \n\r\t\x00()]\+/

syntax region kicadList transparent matchgroup=kicadParen start="(" end=")"

syntax match kicadComment /^[ \n\r\t\x00]*\zs#.*$/ contains=kicadTodo,@Spell
syntax keyword kicadTodo contained TODO FIXME NOTE XXX

" A token is basically a list with a name. `lc=1` makes Vim's syntax engine step
" a single character back before trying to match this pattern, therefore making
" it possible to match it after an opening paren has already been consumed by
" `kicadList`.
syntax match kicadToken /([ \n\r\t\x00]*\w\+[^ \n\r\t\x00()]\@!/lc=1

syntax region kicadString start=/"/ skip=/\\\\\|\\"/ end=/"/ contains=kicadEscaped
" <https://gitlab.com/kicad/code/kicad/-/blob/10.0.3/common/dsnlexer.cpp#L664-715>
syntax match kicadEscaped /\\[\\"abfnrtv]\|\\x\x\{,2}\|\\\o\{,3}/ contained

" <https://gitlab.com/kicad/code/kicad/-/blob/10.0.3/common/dsnlexer.cpp#L493>
" The logic in the linked code is a bit different from the regex that is given
" there, in that it also accepts stuff like `1.` or `12.e3`.
syntax match kicadNumber /\v[^ \n\r\t\x00()]@1<![-+]?%(\d+\.\d*|\.\d+|\d+)%([eE][-+]?\d+)?[^ \n\r\t\x00()]@!/

highlight default link kicadParen   Delimiter
highlight default link kicadString  String
highlight default link kicadEscaped Special
highlight default link kicadNumber  Number
highlight default link kicadToken   Identifier
highlight default link kicadSymbol  Special
highlight default link kicadComment Comment
highlight default link kicadTodo    Todo

let b:current_syntax = 'kicad'

let &cpoptions = s:cpo_save
unlet s:cpo_save
