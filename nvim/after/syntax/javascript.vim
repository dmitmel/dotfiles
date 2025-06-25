syntax sync minlines=1000

if hlexists('javaScriptCommentTodo')
  syn clear javaScriptCommentTodo
  execute 'syn match javaScriptCommentTodo contained' dotfiles#todo_comments#get_pattern()
endif

if hlexists('jsCommentTodo')
  syn clear jsCommentTodo
  execute 'syn match jsCommentTodo contained' dotfiles#todo_comments#get_pattern()
endif

if exists('javascript_plugin_jsdoc')
  syntax match jsDocTags contained '@import' skipwhite nextgroup=jsModuleAsterisk,jsModuleKeyword,jsModuleGroup,jsFlowImportType
endif
