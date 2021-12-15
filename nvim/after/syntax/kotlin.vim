if hlexists('ktTodo')
  syn clear ktTodo
  execute 'syn match ktTodo contained' dotfiles#todo_comments#get_pattern()
endif
