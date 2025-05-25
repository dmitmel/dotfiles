" <https://github.com/tpope/vim-fugitive/blob/4a745ea72fa93bb15dd077109afbb3d1809383f2/syntax/fugitive.vim#L32-L38>

" Meaning of the state characters, take from <https://git-scm.com/docs/git-status#_short_format>:
" M - modified
" T - file type change
" A - added
" D - deleted
" R - renamed
" C - copied
" U - updated but unmerged (I think this means that the file has conflicts)
" ? - untracked

for s:state in ['M Modified', 'A Added', 'D Deleted', '? Untracked']
  exe 'syn match fugitiveState'.s:state[2:].' /'.s:state[0].'/ contained'
  \ 'containedin=fugitiveModifier,fugitiveUntrackedModifier,fugitiveUnstagedModifier,fugitiveStagedModifier'
endfor

hi def link fugitiveStateModified  diffChanged
hi def link fugitiveStateAdded     diffAdded
hi def link fugitiveStateDeleted   diffRemoved
hi def link fugitiveStateUntracked diffAdded
