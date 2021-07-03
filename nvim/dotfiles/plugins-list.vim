let ctx = g:dotfiles_plugins_list_context

" Note about dependencies: In general, they are quite useless. Packs actually
" have no way of specifying load order, but proper plugins don't even depend on
" it because the primary methods of interaction are either calls to autoloaded
" functions (see the dependents of vim-textobj-user), and that will work no
" matter what load order (because all plugins in a pack are first added to RTP,
" only then sourcing begins), or checks in VimEnter (see extension loading in
" vim-airline), and by that time all plugin scripts would have been executed.
" Dependencies are really only useful on plugin installation by the plugin
" manager because packer.nvim, for example, executes plugins in whichever order
" they are downloaded, and doesn't first wait for everything to be downloaded
" to flush everything to RTP.

" Files {{{
  call ctx.use('tpope/vim-eunuch')
  if g:vim_ide
    call ctx.use('francoiscabrol/ranger.vim')
  endif
" }}}

" Editing {{{
  if g:vim_ide
    " call ctx.use('easymotion/vim-easymotion')
    call ctx.use('junegunn/vim-easy-align')
  endif
  call ctx.use('Raimondi/delimitMate')
  call ctx.use('tpope/vim-repeat')
  call ctx.use('tomtom/tcomment_vim')
  call ctx.use('tpope/vim-surround')
  call ctx.use('Yggdroot/indentLine')
  call ctx.use('henrik/vim-indexed-search')
  call ctx.use('andymass/vim-matchup')
  call ctx.use('inkarkat/vim-ingo-library')
  call ctx.use('inkarkat/vim-LineJuggler', { 'branch': 'stable', 'requires': ['vim-ingo-library'] })
  call ctx.use('reedes/vim-pencil')
  call ctx.use('tommcdo/vim-exchange')
  call ctx.use('justinmk/vim-sneak')
" }}}

" Text objects {{{
  call ctx.use('kana/vim-textobj-user')
  call ctx.use('kana/vim-textobj-entire',  { 'requires': ['vim-textobj-user'] })
  call ctx.use('kana/vim-textobj-line',    { 'requires': ['vim-textobj-user'] })
  call ctx.use('kana/vim-textobj-indent',  { 'requires': ['vim-textobj-user'] })
  call ctx.use('glts/vim-textobj-comment', { 'requires': ['vim-textobj-user'] })
" }}}

" UI {{{
  call ctx.use('moll/vim-bbye')
  call ctx.use('gerw/vim-HiLinkTrace')
  call ctx.use('vim-airline/vim-airline')
  call ctx.use('tpope/vim-obsession')
  call ctx.use('romainl/vim-qf')
" }}}

" Git {{{
  if g:vim_ide
    call ctx.use('tpope/vim-fugitive')
    call ctx.use('tpope/vim-rhubarb')
    call ctx.use('airblade/vim-gitgutter')
  endif
" }}}

" FZF {{{
  call ctx.use('junegunn/fzf', { 'run': './install --bin' })
  call ctx.use('junegunn/fzf.vim')
" }}}

" " Programming {{{
  let g:polyglot_disabled = ['sensible']
  call ctx.use('sheerun/vim-polyglot')
  call ctx.use('chikamichi/mediawiki.vim')
  call ctx.use('ron-rs/ron.vim')
  call ctx.use('kylelaker/riscv.vim')
  if g:vim_ide
    call ctx.use('neoclide/coc.nvim', { 'branch': 'master', 'run': 'yarn install --frozen-lockfile' })
    call ctx.use('dag/vim2hs')
    call ctx.use('norcalli/nvim-colorizer.lua')
    if g:vim_ide_treesitter
      call ctx.use('nvim-treesitter/nvim-treesitter', { 'run': ':TSUpdate' })
    endif
  endif
" }}}
