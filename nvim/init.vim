let g:nvim_dotfiles_dir = expand('<sfile>:p:h')

let g:vim_ide = get(g:, 'vim_ide', 0)
let g:vim_ide_treesitter = get(g:, 'vim_ide_treesitter', 0)

let &runtimepath = g:nvim_dotfiles_dir.','.&runtimepath.','.g:nvim_dotfiles_dir.'/after'


let s:vim_config_dir = stdpath("config")
let s:vim_plug_script = s:vim_config_dir . '/autoload/plug.vim'
let s:vim_plug_home = s:vim_config_dir . '/plugged'

let s:just_installed_vim_plug = 0
if !filereadable(s:vim_plug_script)
  execute '!curl -fL https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim --create-dirs -o' shellescape(s:vim_plug_script)
  autocmd VimEnter * PlugInstall --sync
endif

call plug#begin(s:vim_plug_home)
Plug 'junegunn/vim-plug'
runtime! dotfiles/plugins-list.vim
call plug#end()
if g:vim_ide_treesitter
  runtime! dotfiles/treesitter.vim
endif

" Automatically install/clean plugins (because I'm a programmer) {{{
  augroup vimrc-plugins
    autocmd!
    autocmd VimEnter *
      \  if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
      \|   PlugInstall --sync | q
      \| endif
  augroup END
" }}}

colorscheme dotfiles
