if hlexists('vimTodo')
  syn clear vimTodo
  execute 'syn match vimTodo contained' dotfiles#todo_comments#get_pattern()
endif

syntax match Boolean  "\<v:true\>"  contained containedin=vimVimVar
syntax match Boolean  "\<v:false\>" contained containedin=vimVimVar
syntax match Constant "\<v:null\>"  contained containedin=vimVimVar

" Word operators: `is#`, `isnot?`
syntax match Keyword  "\a\+"        contained containedin=vimOper

" Patch the `matchgroup=...` argument on this line:
" <https://github.com/neovim/neovim/blob/v0.10.0/runtime/syntax/vim.vim#L797>
" <https://github.com/neovim/neovim/commit/b5e3df37a436b7760495ce0d44f9dcb009915149>
if exists('*execute') && dotutils#syn_exists('vimHiLink')
  let s:lines = split(execute('syntax list vimHiLink'), '\n')
  if s:lines[0] =~# '^---.*---$'
    let s:definition = matchstr(s:lines[1], '^vimHiLink\s\+xxx\s\+\zs.*$')
    let s:fixed_def = substitute(s:definition, '\<matchgroup=Type\>', 'matchgroup=vimCommand', '')
    if !empty(s:fixed_def) && s:fixed_def !=# s:definition
      syntax clear vimHiLink
      execute 'syntax region vimHiLink' s:fixed_def
    endif
    unlet s:definition s:fixed_def
  endif
  unlet s:lines
endif
