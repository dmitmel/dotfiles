if hlexists('shTodo')
  syn clear shTodo
  execute 'syn match shTodo contained' dotfiles#todo_comments#get_pattern()
endif
