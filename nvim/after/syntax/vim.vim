if hlexists('vimTodo')
  syn clear vimTodo
  execute 'syn match vimTodo contained' dotfiles#todo_comments#get_pattern()
endif

syntax match Boolean  "\<v:true\>"  contained containedin=vimVimVar
syntax match Boolean  "\<v:false\>" contained containedin=vimVimVar
syntax match Constant "\<v:null\>"  contained containedin=vimVimVar
syntax match Keyword  "\a\+"        contained containedin=vimOper
