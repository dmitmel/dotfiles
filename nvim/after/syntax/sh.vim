" <https://github.com/vim/vim/blob/23984602327600b7ef28dcedc772949d5c66b57f/runtime/syntax/zsh.vim#L315>
syn match shShebang '^\%1l#!.*$'

" <https://github.com/lunacookies/vim-sh/blob/cebda390c56654a4c9f96f66727e9be076a7aee3/syntax/sh.vim#L19-L21>
syn match Constant "\v/dev/\w+" containedin=shFunctionOne,shIf,shCmdParenRegion,shCommandSub

hi def link shShebang PreProc

if hlexists('shTodo')
  syn clear shTodo
  execute 'syn match shTodo contained' dotfiles#todo_comments#get_pattern()
endif
