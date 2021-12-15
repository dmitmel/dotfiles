if !hlexists('htmlTodo') && hlexists('htmlComment')
  execute 'syn match htmlTodo contained containedin=htmlComment' dotfiles#todo_comments#get_pattern()
  hi def link htmlTodo Todo
elseif hlexists('htmlTodo')
  syn clear htmlTodo
  execute 'syn match htmlTodo contained' dotfiles#todo_comments#get_pattern()
endif
