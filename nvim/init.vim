let g:nvim_dotfiles_dir = expand('<sfile>:p:h')

let g:vim_ide = get(g:, 'vim_ide', 0)

let &runtimepath = g:nvim_dotfiles_dir.','.&runtimepath.','.g:nvim_dotfiles_dir.'/after'

for s:name in ['plugins', 'editing', 'interface', 'files', 'completion', 'terminal', 'git']
  execute 'source' fnameescape(g:nvim_dotfiles_dir.'/lib/'.s:name.'.vim')
endfor

colorscheme dotfiles

for s:path in globpath(g:nvim_dotfiles_dir.'/lib/languages', '*', 0, 1)
  execute 'source' fnameescape(s:path)
endfor
