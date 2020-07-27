let g:nvim_dotfiles_dir = expand('<sfile>:p:h')

let g:vim_ide = get(g:, 'vim_ide', 0)

let &runtimepath = g:nvim_dotfiles_dir.','.&runtimepath.','.g:nvim_dotfiles_dir.'/after'


let s:vim_config_dir = stdpath("config")
let s:vim_plug_script = s:vim_config_dir . '/autoload/plug.vim'
let s:vim_plug_home = s:vim_config_dir . '/plugged'

let s:just_installed_vim_plug = 0
if !filereadable(s:vim_plug_script)
  execute '!curl -fL https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim --create-dirs -o' shellescape(s:vim_plug_script)
  autocmd VimEnter * PlugInstall --sync
endif

call plug#begin(s:vim_config_dir . '/plugged')

Plug 'junegunn/vim-plug'

" Files {{{
  Plug 'tpope/vim-eunuch'
  if g:vim_ide
    Plug 'francoiscabrol/ranger.vim'
  endif
" }}}

" Editing {{{
  if g:vim_ide
    Plug 'easymotion/vim-easymotion'
    Plug 'junegunn/vim-easy-align'
  endif
  Plug 'Raimondi/delimitMate'
  Plug 'tpope/vim-repeat'
  Plug 'tpope/vim-commentary'
  Plug 'tpope/vim-surround'
  Plug 'Yggdroot/indentLine'
  Plug 'henrik/vim-indexed-search'
  Plug 'andymass/vim-matchup'
  Plug 'inkarkat/vim-ingo-library'  " required by LineJuggler
  Plug 'inkarkat/vim-LineJuggler', { 'branch': 'stable' }
  Plug 'reedes/vim-pencil'
  Plug 'ciaranm/detectindent'
  Plug 'tommcdo/vim-exchange'
" }}}

" Text objects {{{
  Plug 'kana/vim-textobj-user'
  Plug 'kana/vim-textobj-entire'
  Plug 'kana/vim-textobj-line'
  Plug 'kana/vim-textobj-indent'
" }}}

" UI {{{
  Plug 'moll/vim-bbye'
  Plug 'gerw/vim-HiLinkTrace'
  Plug 'vim-airline/vim-airline'
  Plug 'tpope/vim-obsession'
  Plug 'romainl/vim-qf'
  if g:vim_ide
    Plug 'dyng/ctrlsf.vim'
  endif
" }}}

" Git {{{
  if g:vim_ide
    Plug 'tpope/vim-fugitive'
    Plug 'tpope/vim-rhubarb'
    Plug 'airblade/vim-gitgutter'
  endif
" }}}

" FZF {{{
  Plug 'junegunn/fzf', { 'do': './install --bin' }
  Plug 'junegunn/fzf.vim'
" }}}

" Programming {{{
  Plug 'sheerun/vim-polyglot'
  if g:vim_ide
    Plug 'neoclide/coc.nvim', { 'branch': 'release' }
    Plug 'dag/vim2hs'
  endif
" }}}

call plug#end()

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
