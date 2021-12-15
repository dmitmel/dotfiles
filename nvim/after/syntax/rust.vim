syn keyword rustOperatorKeyword as
hi def link rustOperatorKeyword Keyword

if hlexists('rustTodo')
  syn clear rustTodo
  execute 'syn match rustTodo contained' dotfiles#todo_comments#get_pattern()
endif
