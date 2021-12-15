if hlexists('awkTodo')
  syn clear awkTodo
  execute 'syn match awkTodo contained' dotfiles#todo_comments#get_pattern()
endif
