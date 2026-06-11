if hlexists('xmlTodo')
  syntax clear xmlTodo
  execute 'syntax match xmlTodo contained' dotfiles#todo_comments#get_pattern()
endif

syntax match xmlDeclaration contained /<?xml\>/lc=2 containedin=xmlProcessing
highlight default link xmlDeclaration PreProc
