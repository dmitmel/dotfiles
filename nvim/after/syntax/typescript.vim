source <sfile>:h/javascript.vim

" <https://github.com/HerringtonDarkholme/yats.vim/blob/b325c449a2db4d9ee38aa441afa850a815982e8b/syntax/common.vim#L11-L12>
setlocal iskeyword-=#

if hlexists('typescriptCommentTodo')
  syn clear typescriptCommentTodo
  execute 'syn match typescriptCommentTodo contained' dotfiles#todo_comments#get_pattern()
endif
