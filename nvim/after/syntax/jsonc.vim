if hlexists('jsonCommentTodo')
  syn clear jsonCommentTodo
  execute 'syn match jsonCommentTodo contained' dotfiles#todo_comments#get_pattern()
endif
