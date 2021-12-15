if hlexists('luaTodo')
  syn clear luaTodo
  execute 'syn match luaTodo contained' dotfiles#todo_comments#get_pattern()
endif
if hlexists('luaCommentTodo')
  syn clear luaCommentTodo
  execute 'syn match luaCommentTodo contained' dotfiles#todo_comments#get_pattern()
endif
