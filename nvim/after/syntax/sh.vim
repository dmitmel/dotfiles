" <https://github.com/vim/vim/blob/23984602327600b7ef28dcedc772949d5c66b57f/runtime/syntax/zsh.vim#L315>
syn match shShebang /^\%1l#!.*$/

" <https://github.com/lunacookies/vim-sh/blob/cebda390c56654a4c9f96f66727e9be076a7aee3/syntax/sh.vim#L19-L21>
syn match shDevPath "/dev/\w\+"
syn cluster shCommandSubList add=shDevPath

hi def link shDevPath Constant
hi def link shShebang PreProc

" For some reason, the default syntax file doesn't recognize ifs, loops or
" function definitions sitting inside subshells, so add more syntax items to the
" ones that can be contained within subshell parentheses. Also, since @shIfList
" contains @shLoopList, which contains @shCaseList, which in turn contains
" @shCommandSubList, this line links all of these four clusters in a circle and
" makes them effectively the same, but I don't think the shell language has any
" differences on what can go inside ifs/loops/functions/substitutions/subshells,
" and Vim can cope with such recursive `contains` lists just fine.
syn cluster shCommandSubList add=@shIfList,@shFunctionDefList
" This group was probably added by mistake. It makes the angle brackets used for
" I/O redirections highlighted as comparison operators.
syn cluster shLoopList remove=shTestOpr

if hlexists('shTodo')
  syn clear shTodo
  execute 'syn match shTodo contained' dotfiles#todo_comments#get_pattern()
endif
