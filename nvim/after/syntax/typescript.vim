source <sfile>:h/javascript.vim

" <https://github.com/sheerun/vim-polyglot/blob/c96947b1c64c56f70125a9bac9c006f69e45d5d3/syntax/common.vim#L18-L19>
setlocal iskeyword-=#

if hlexists('typescriptCommentTodo')
  syn clear typescriptCommentTodo
  execute 'syn match typescriptCommentTodo contained' dotfiles#todo_comments#get_pattern()
endif
