if hlexists('riscvTodo')
  syn clear riscvTodo
  execute 'syn match riscvTodo containedin=riscvComment' dotfiles#todo_comments#get_pattern()
endif
