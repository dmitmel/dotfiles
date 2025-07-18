if hlexists('luaTodo')
  syn clear luaTodo
  execute 'syn match luaTodo contained' dotfiles#todo_comments#get_pattern()
endif

if hlexists('luaCommentTodo')
  syn clear luaCommentTodo
  execute 'syn match luaCommentTodo contained' dotfiles#todo_comments#get_pattern()
endif

if !exists('lua_syntax_nostdlib')
  syn keyword luaSpecialTable vim
endif
