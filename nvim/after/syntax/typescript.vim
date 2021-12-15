source <sfile>:h/javascript.vim

if hlexists('typescriptCommentTodo')
  syn clear typescriptCommentTodo
  execute 'syn match typescriptCommentTodo contained' dotfiles#todo_comments#get_pattern()
endif
