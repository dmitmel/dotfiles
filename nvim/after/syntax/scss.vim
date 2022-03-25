syntax sync minlines=500

" The VIMRUNTIME syntax file sources the syntax files for SASS (from
" runtimepath, so it will load my todo-comment patch with it) and makes a few
" minor modifications to the rules to accomodate for SCSS, vim-polyglot defines
" an entirely separate file for SCSS with its own hlgroups, so this branch will
" only execute for vim-polyglot's syntax file.
if hlexists('scssTodo')
  syn clear scssTodo
  execute 'syn match scssTodo contained containedin=@comment' dotfiles#todo_comments#get_pattern()
endif
