if hlexists('zshTodo')
  syn clear zshTodo
  execute 'syn match zshTodo contained' dotfiles#todo_comments#get_pattern()
endif
