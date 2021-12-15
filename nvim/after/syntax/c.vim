if hlexists('cTodo')
  syn clear cTodo
  execute 'syn match cTodo contained' dotfiles#todo_comments#get_pattern()
endif
