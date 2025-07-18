if hlexists('jsonCommentTodo')
  syn clear jsonCommentTodo
  execute 'syn match jsonCommentTodo contained' dotfiles#todo_comments#get_pattern()
endif

if get(g:, 'vim_json_warnings', 1)
  syn clear jsonCommentError
  syn clear jsonTrailingCommaError
endif
