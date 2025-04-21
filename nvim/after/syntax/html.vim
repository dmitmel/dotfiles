" <https://github.com/vim/vim/blob/23984602327600b7ef28dcedc772949d5c66b57f/runtime/syntax/xml.vim#L82>
syn match htmlEqual '=' containedin=htmlTag

if !hlexists('htmlTodo') && hlexists('htmlComment')
  execute 'syn match htmlTodo contained containedin=htmlComment' dotfiles#todo_comments#get_pattern()
  hi def link htmlTodo Todo
elseif hlexists('htmlTodo')
  syn clear htmlTodo
  execute 'syn match htmlTodo contained' dotfiles#todo_comments#get_pattern()
endif
