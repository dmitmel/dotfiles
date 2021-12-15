if hlexists('rubyTodo')
  syn clear rubyTodo
  execute 'syn match rubyTodo contained' dotfiles#todo_comments#get_pattern()
endif
