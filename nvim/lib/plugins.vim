let s:dein_plugins_dir = expand('~/.cache/dein')
let s:dein_dir = s:dein_plugins_dir . '/repos/github.com/Shougo/dein.vim'

if !isdirectory(s:dein_dir)
  echo 'Installing Dein...'
  call system('git clone https://github.com/Shougo/dein.vim ' . shellescape(s:dein_dir))
endif

let &runtimepath .= ',' . s:dein_dir

if dein#load_state(s:dein_plugins_dir)
  call dein#begin(s:dein_plugins_dir)

  command! -nargs=+ -bar Plugin call dein#add(<args>)

  " Let dein manage itself
  Plugin s:dein_dir

  " Files {{{
    Plugin 'tpope/vim-eunuch'
    Plugin 'francoiscabrol/ranger.vim'
  " }}}

  " Editing {{{
    Plugin 'easymotion/vim-easymotion'
    Plugin 'junegunn/vim-easy-align'
    Plugin 'Raimondi/delimitMate'
    Plugin 'tpope/vim-repeat'
    Plugin 'tpope/vim-commentary'
    Plugin 'tpope/vim-surround'
    Plugin 'Yggdroot/indentLine'
    Plugin 'henrik/vim-indexed-search'
    Plugin 'andymass/vim-matchup'
    Plugin 'tommcdo/vim-exchange'
    Plugin 'inkarkat/vim-ingo-library'  " required by LineJuggler
    Plugin 'inkarkat/vim-LineJuggler', { 'rev': 'stable' }
    Plugin 'reedes/vim-pencil'
  " }}}

  " Text objects {{{
    Plugin 'kana/vim-textobj-user'
    Plugin 'kana/vim-textobj-entire'
    Plugin 'kana/vim-textobj-line'
    Plugin 'kana/vim-textobj-indent'
    " Plugin 'kana/vim-textobj-fold'
  " }}}

  " UI {{{
    Plugin 'moll/vim-bbye'
    Plugin 'gerw/vim-HiLinkTrace'
    Plugin 'vim-airline/vim-airline'
    Plugin 'vim-airline/vim-airline-themes'
    Plugin 'wincent/terminus'
    Plugin 'tpope/vim-obsession'
    Plugin 'romainl/vim-qf'
    Plugin 'dyng/ctrlsf.vim'
  " }}}

  " Git {{{
    Plugin 'tpope/vim-fugitive'
    Plugin 'tpope/vim-rhubarb'
    Plugin 'airblade/vim-gitgutter'
  " }}}

  " FZF {{{
    Plugin 'junegunn/fzf', { 'build': './install --bin' }
    Plugin 'junegunn/fzf.vim'
  " }}}

  " Programming {{{
    Plugin 'sheerun/vim-polyglot'
    Plugin 'neoclide/coc.nvim', { 'build': 'yarn install' }
    Plugin 'dag/vim2hs'
  " }}}

  delcommand Plugin

  call dein#end()
  call dein#save_state()
endif

" enable full plugin support
filetype plugin indent on
syntax enable

" Automatically install/clean plugins (because I'm a programmer) {{{

  " the following two lines were copied directly from dein's source code
  let s:dein_cache_dir = get(g:, 'dein#cache_directory', g:dein#_base_path)
  let s:dein_state_file = s:dein_cache_dir . '/state_' . g:dein#_progname . '.vim'

  let s:current_file = expand('<sfile>')

  " gettftime() returns the last modification time of a given file
  let s:plugins_file_changed = getftime(s:current_file) > getftime(s:dein_state_file)
  if s:plugins_file_changed
    echo "plugins.vim was changed, clearing Dein state..."
    call dein#clear_state()

    let s:unused_plugins = dein#check_clean()
    if !empty(s:unused_plugins)
      echo "Cleaning up unused plugins..."
      for s:plugin in s:unused_plugins
        echo "deleting" s:plugin
        call delete(s:plugin, 'rf')
      endfor
    endif
  endif

  if dein#check_install() || s:plugins_file_changed
    echo "Installing plugins..."
    call dein#install()
    echo
  endif

" }}}
