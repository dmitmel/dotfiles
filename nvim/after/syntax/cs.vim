if hlexists('csTodo')
  syn clear csTodo
  execute 'syn match csTodo contained' dotfiles#todo_comments#get_pattern()
endif
