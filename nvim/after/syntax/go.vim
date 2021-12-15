if hlexists('goTodo')
  syn clear goTodo
  execute 'syn match goTodo contained' dotfiles#todo_comments#get_pattern()
endif
