if hlexists('haskellTodo')
  syn clear haskellTodo
  execute 'syn match haskellTodo contained' dotfiles#todo_comments#get_pattern()
endif
