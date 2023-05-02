if get(g:, 'main_syntax', '') !=# 'jsonc'
  syntax match Comment +\/\/.\+$+
endif

if hlexists('jsonCommentTodo')
  syn clear jsonCommentTodo
  execute 'syn match jsonCommentTodo contained' dotfiles#todo_comments#get_pattern()
endif
