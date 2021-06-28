" Files {{{
  Plug 'tpope/vim-eunuch'
  if g:vim_ide
    Plug 'francoiscabrol/ranger.vim'
  endif
" }}}

" Editing {{{
  if g:vim_ide
    " Plug 'easymotion/vim-easymotion'
    Plug 'junegunn/vim-easy-align'
  endif
  Plug 'Raimondi/delimitMate'
  Plug 'tpope/vim-repeat'
  Plug 'tomtom/tcomment_vim'
  Plug 'tpope/vim-surround'
  Plug 'Yggdroot/indentLine'
  Plug 'henrik/vim-indexed-search'
  Plug 'andymass/vim-matchup'
  Plug 'inkarkat/vim-ingo-library'  " required by LineJuggler
  Plug 'inkarkat/vim-LineJuggler', { 'branch': 'stable' }
  Plug 'reedes/vim-pencil'
  Plug 'tommcdo/vim-exchange'
  Plug 'justinmk/vim-sneak'
" }}}

" Text objects {{{
  Plug 'kana/vim-textobj-user'
  Plug 'kana/vim-textobj-entire'
  Plug 'kana/vim-textobj-line'
  Plug 'kana/vim-textobj-indent'
  Plug 'glts/vim-textobj-comment'
" }}}

" UI {{{
  Plug 'moll/vim-bbye'
  Plug 'gerw/vim-HiLinkTrace'
  Plug 'vim-airline/vim-airline'
  Plug 'tpope/vim-obsession'
  Plug 'romainl/vim-qf'
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
  let g:polyglot_disabled = ['sensible']
  Plug 'sheerun/vim-polyglot'
  Plug 'chikamichi/mediawiki.vim'
  Plug 'ron-rs/ron.vim'
  Plug 'kylelaker/riscv.vim'
  if g:vim_ide
    Plug 'neoclide/coc.nvim', { 'branch': 'release' }
    Plug 'dag/vim2hs'
    Plug 'norcalli/nvim-colorizer.lua'
    if g:vim_ide_treesitter
      Plug 'nvim-treesitter/nvim-treesitter', { 'do': ':TSUpdate' }
    endif
  endif
" }}}
