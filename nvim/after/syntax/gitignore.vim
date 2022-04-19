if hlexists('gitignoreTodo')
  syn clear gitignoreTodo
  execute 'syn match gitignoreTodo contained' dotfiles#todo_comments#get_pattern()
endif
