if hlexists('tomlTodo')
  syn clear tomlTodo
  execute 'syn match tomlTodo contained' dotfiles#todo_comments#get_pattern()
endif
