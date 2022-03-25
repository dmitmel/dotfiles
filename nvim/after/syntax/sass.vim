syntax sync minlines=500

if hlexists('sassTodo')
  syn clear sassTodo
  execute 'syn match sassTodo contained' dotfiles#todo_comments#get_pattern()
endif
