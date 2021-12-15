if hlexists('javaTodo')
  syn clear javaTodo
  execute 'syn match javaTodo contained' dotfiles#todo_comments#get_pattern()
endif
