if hlexists('xmlTodo')
  syn clear xmlTodo
  execute 'syn match xmlTodo contained' dotfiles#todo_comments#get_pattern()
endif
