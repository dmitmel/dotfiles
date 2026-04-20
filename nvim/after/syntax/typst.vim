syntax match typstEscaped /\\\%(u{\x*}\|.\)/ containedin=typstCodeString
syntax cluster typstMarkup add=typstEscaped

syntax clear typstMarkupHeading
syntax match typstMarkupHeading /^\s*\zs=\{1,6}\s.*$/ contains=@typstMarkup,@Spell

highlight default link typstEscaped Special

if hlexists('typstCommentTodo')
  syn clear typstCommentTodo
  execute 'syn match typstCommentTodo contained' dotfiles#todo_comments#get_pattern()
endif
