let s:saved_syntax = b:current_syntax
unlet! b:current_syntax
syntax include @gdbPython syntax/python.vim
let b:current_syntax = s:saved_syntax
unlet! s:saved_syntax

" NOTE: `matchgroup` must come before `start` and `end` patterns! It applies
" hlgroups only to the patterns that follow it.
syn region gdbPythonBlock
      \ matchgroup=gdbStatement
      \ start=/^\s*\zs\%(py\%[thon-interactive]\|pi\)\ze\s*$/ end=/^\s*\zsend\ze\s*$/ keepend
      \ contains=@gdbPython
syn region gdbInlinePython
      \ matchgroup=gdbStatement
      \ start=/^\s*\zs\%(py\%[thon-interactive]\|pi\)\ze\s\+\S/ end=/$/ keepend
      \ contains=@gdbPython
