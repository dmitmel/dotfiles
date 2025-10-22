if hlexists('vimTodo')
  syn clear vimTodo
  execute 'syn match vimTodo contained' dotfiles#todo_comments#get_pattern()
endif

syn match vimBoolean "\<v:true\>"  nextgroup=vimSubscript
syn match vimBoolean "\<v:false\>" nextgroup=vimSubscript
syn match vimNull    "\<v:null\>"  nextgroup=vimSubscript

syn cluster vimSpecialVar add=vimBoolean,vimNull

hi def link vimBoolean  Boolean
hi def link vimNull     Constant
