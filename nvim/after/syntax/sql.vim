if hlexists('sqlTodo')
  syn clear sqlTodo
  execute 'syn match sqlTodo contained' dotfiles#todo_comments#get_pattern()
endif
