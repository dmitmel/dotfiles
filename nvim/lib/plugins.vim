let s:vim_config_dir = expand('~/.config/nvim')
let s:vim_plug_script = s:vim_config_dir . '/autoload/plug.vim'
let s:vim_plug_home = s:vim_config_dir . '/plugged'

let s:just_installed_vim_plug = 0
if !filereadable(s:vim_plug_script)
  exe '!curl -fL https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim --create-dirs -o' shellescape(s:vim_plug_script)
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
  Plug 'easymotion/vim-easymotion'
  Plug 'junegunn/vim-easy-align'
  Plug 'Raimondi/delimitMate'
  Plug 'tpope/vim-repeat'
  Plug 'tpope/vim-commentary'
  Plug 'tpope/vim-surround'
  Plug 'Yggdroot/indentLine'
  Plug 'henrik/vim-indexed-search'
  Plug 'andymass/vim-matchup'
  " Plug 'tommcdo/vim-exchange'
  Plug 'inkarkat/vim-ingo-library'  " required by LineJuggler
  Plug 'inkarkat/vim-LineJuggler', { 'branch': 'stable' }
  Plug 'reedes/vim-pencil'
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
  Plug 'vim-airline/vim-airline-themes'
  Plug 'tpope/vim-obsession'
  Plug 'romainl/vim-qf'
  if g:vim_ide
    Plug 'dyng/ctrlsf.vim'
  endif
" }}}

" Git {{{
  Plug 'tpope/vim-fugitive'
  Plug 'tpope/vim-rhubarb'
  Plug 'airblade/vim-gitgutter'
" }}}

" FZF {{{
  Plug 'junegunn/fzf', { 'do': './install --bin' }
  Plug 'junegunn/fzf.vim'
" }}}

" Programming {{{
  Plug 'sheerun/vim-polyglot'
  if g:vim_ide
    Plug 'neoclide/coc.nvim', { 'do': 'yarn install' }
    Plug 'dag/vim2hs'
  endif
" }}}

call plug#end()

" " Automatically install/clean plugins (because I'm a programmer) {{{
  augroup vimrc-plugins
    autocmd!
    autocmd VimEnter *
      \  if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
      \|   PlugInstall --sync | q
      \| endif
  augroup END
" " }}}
