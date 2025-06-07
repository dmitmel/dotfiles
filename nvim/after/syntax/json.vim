" Patch support for comments into all JSON files.
" <https://github.com/neovim/neovim/blob/v0.6.0/runtime/syntax/jsonc.vim#L31-L38>

if hlexists('jsonCommentTodo')
  syn clear jsonCommentTodo
  hi def link jsonCommentTodo Todo
endif
execute 'syn match jsonCommentTodo contained' dotfiles#todo_comments#get_pattern()

if get(g:, 'main_syntax', '') !=# 'jsonc'
  if !hlexists('jsonLineComment')
    syn region  jsonLineComment  start='\/\/' end='$'   contains=@Spell,jsonCommentTodo keepend
    hi def link jsonLineComment  Comment
  endif
  if !hlexists('jsonComment')
    syn region  jsonComment      start='/\*'  end='\*/' contains=@Spell,jsonCommentTodo fold
    hi def link jsonComment      Comment
  endif
endif
