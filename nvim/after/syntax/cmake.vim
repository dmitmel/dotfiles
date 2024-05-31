if hlexists('cmakeTodo')
  syn clear cmakeTodo
  execute 'syn match cmakeTodo contained' dotfiles#todo_comments#get_pattern()
endif
