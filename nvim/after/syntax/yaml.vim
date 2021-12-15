if hlexists('yamlTodo')
  syn clear yamlTodo
  execute 'syn match yamlTodo contained' dotfiles#todo_comments#get_pattern()
endif
