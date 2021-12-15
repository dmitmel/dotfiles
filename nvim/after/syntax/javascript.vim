syntax sync minlines=500

if hlexists('javaScriptCommentTodo')
  syn clear javaScriptCommentTodo
  execute 'syn match javaScriptCommentTodo contained' dotfiles#todo_comments#get_pattern()
endif

if hlexists('jsCommentTodo')
  syn clear jsCommentTodo
  execute 'syn match jsCommentTodo contained' dotfiles#todo_comments#get_pattern()
endif
