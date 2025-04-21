" <https://github.com/lunacookies/vim-sh/blob/cebda390c56654a4c9f96f66727e9be076a7aee3/syntax/sh.vim#L16-L21>
syn match zshOption "\s\zs[-+][-_a-zA-Z#@]\+"
syn match zshOption "\s\zs--[^ \t$=`'"|);]\+"

" <https://github.com/lunacookies/vim-sh/blob/cebda390c56654a4c9f96f66727e9be076a7aee3/syntax/sh.vim#L19-L21>
syn match Constant "\v/dev/\w+" containedin=shFunctionOne,shIf,shCmdParenRegion,shCommandSub

syn keyword zshRepeat in

if hlexists('zshTodo')
  syn clear zshTodo
  execute 'syn match zshTodo contained' dotfiles#todo_comments#get_pattern()
endif
