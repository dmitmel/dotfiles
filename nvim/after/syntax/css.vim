if !hlexists('cssTodo') && hlexists('cssComment')
  execute 'syn match cssTodo contained containedin=cssComment' dotfiles#todo_comments#get_pattern()
  hi def link cssTodo Todo
elseif hlexists('cssTodo')
  syn clear cssTodo
  execute 'syn match cssTodo contained' dotfiles#todo_comments#get_pattern()
endif
