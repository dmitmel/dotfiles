let g:nvim_dotfiles_dir = expand('<sfile>:p:h')

let g:vim_ide = get(g:, 'vim_ide', 0)

for s:name in ['plugins', 'editing', 'interface', 'colorscheme', 'files', 'completion', 'terminal', 'git']
  execute 'source' fnameescape(g:nvim_dotfiles_dir.'/lib/'.s:name.'.vim')
endfor

for s:path in globpath(g:nvim_dotfiles_dir.'/lib/languages', '*', 0, 1)
  execute 'source' fnameescape(s:path)
endfor
