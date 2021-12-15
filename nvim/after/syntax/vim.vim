if hlexists('vimTodo')
  syn clear vimTodo
  execute 'syn match vimTodo contained' dotfiles#todo_comments#get_pattern()
endif
