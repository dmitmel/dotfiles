" Check for the presence of this commit:
" <https://github.com/neovim/neovim/commit/6ad73421cbfc42d63e8e2d3522ef1e6b9ed48855>
try
  silent syntax list @gdbPython
  let s:has_embedded_python = 1
catch /^Vim\%((\a\+)\)\=:E392:/  " No such syntax cluster: @gdbPython
  let s:has_embedded_python = 0
endtry

if !s:has_embedded_python
  let s:saved_syntax = b:current_syntax
  unlet b:current_syntax
  syntax include @gdbPython syntax/python.vim
  let b:current_syntax = s:saved_syntax
  unlet s:saved_syntax

  " NOTE: `matchgroup` must come before `start` and `end` patterns! It applies
  " hlgroups only to the patterns that follow it.
  syntax region gdbPythonBlock
    \ matchgroup=gdbStatement
    \ start=/^\s*\zs\%(py\%[thon-interactive]\|pi\)\ze\s*$/ end=/^\s*\zsend\ze\s*$/ keepend
    \ contains=@gdbPython
  syntax region gdbInlinePython
    \ matchgroup=gdbStatement
    \ start=/^\s*\zs\%(py\%[thon-interactive]\|pi\)\ze\s\+\S/ end=/$/ keepend
    \ contains=@gdbPython
endif

unlet s:has_embedded_python
