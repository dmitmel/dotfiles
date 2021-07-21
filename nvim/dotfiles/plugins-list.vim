let s:ctx = g:dotfiles_plugins_list_context

" Note about dependencies: In general, they are quite useless. Packs actually
" have no way of specifying load order, but proper plugins don't even depend on
" it because the primary methods of interaction are either calls to autoloaded
" functions (see the dependents of vim-textobj-user), and that will work no
" matter what load order (because all plugins in a pack are first added to RTP,
" only then sourcing begins), or checks in VimEnter (see extension loading in
" vim-airline), and by that time all plugin scripts would have been executed.
" Dependencies (As specified with `after`, not with `requires`! See
" <https://github.com/wbthomason/packer.nvim/issues/87>) are really only useful
" on plugin installation by the plugin manager because packer.nvim, for
" example, executes plugins in whichever order they are downloaded, and doesn't
" first wait for everything to be downloaded to flush everything to
" RTP.

" COUNTERHACK: Don't specify dependencies. Just don't.

" Files {{{
  call s:ctx.use('tpope/vim-eunuch')
  if g:vim_ide
    call s:ctx.use('francoiscabrol/ranger.vim')
  endif
" }}}

" Editing {{{
  if g:vim_ide
    " call s:ctx.use('easymotion/vim-easymotion')
    call s:ctx.use('junegunn/vim-easy-align')
  endif
  call s:ctx.use('Raimondi/delimitMate')
  call s:ctx.use('tpope/vim-repeat')
  call s:ctx.use('tomtom/tcomment_vim')
  call s:ctx.use('tpope/vim-surround')
  " if has('nvim-0.5.0')
  "   " Doesn't use concealed text, can put indent guides on blank lines, depends
  "   " on <https://github.com/neovim/neovim/pull/13952/files>, backwards
  "   " compatible with the original indentLine (in terms of options). ...And has
  "   " a critical bug:
  "   " <https://github.com/lukas-reineke/indent-blankline.nvim/issues/51>
  "   call s:ctx.use('lukas-reineke/indent-blankline.nvim')
  " else
    call s:ctx.use('Yggdroot/indentLine')
  " endif
  call s:ctx.use('henrik/vim-indexed-search')
  call s:ctx.use('andymass/vim-matchup')
  call s:ctx.use('inkarkat/vim-ingo-library')
  call s:ctx.use('inkarkat/vim-LineJuggler', { 'branch': 'stable' })
  call s:ctx.use('reedes/vim-pencil')
  call s:ctx.use('tommcdo/vim-exchange')
  call s:ctx.use('justinmk/vim-sneak')
" }}}

" Text objects {{{
  call s:ctx.use('kana/vim-textobj-user')
  call s:ctx.use('kana/vim-textobj-entire')
  call s:ctx.use('kana/vim-textobj-line')
  call s:ctx.use('kana/vim-textobj-indent')
  call s:ctx.use('glts/vim-textobj-comment')
" }}}

" UI {{{
  call s:ctx.use('moll/vim-bbye')
  call s:ctx.use('gerw/vim-HiLinkTrace')
  call s:ctx.use('vim-airline/vim-airline')
  call s:ctx.use('tpope/vim-obsession')
  call s:ctx.use('romainl/vim-qf')
" }}}

" Git {{{
  if g:vim_ide
    call s:ctx.use('tpope/vim-fugitive')
    call s:ctx.use('tpope/vim-rhubarb')
    call s:ctx.use('airblade/vim-gitgutter')
  endif
" }}}

" FZF {{{
  call s:ctx.use('junegunn/fzf', { 'run': './install --bin' })
  call s:ctx.use('junegunn/fzf.vim')
" }}}

" " Programming {{{
  let g:polyglot_disabled = ['sensible']
  call s:ctx.use('sheerun/vim-polyglot')
  call s:ctx.use('chikamichi/mediawiki.vim')
  call s:ctx.use('ron-rs/ron.vim')
  call s:ctx.use('kylelaker/riscv.vim')
  if g:vim_ide
    call s:ctx.use('neoclide/coc.nvim', { 'branch': 'master', 'run': 'yarn install --frozen-lockfile' })
    call s:ctx.use('fannheyward/coc-rust-analyzer', { 'run': 'yarn install --frozen-lockfile' })
    " call s:ctx.use('neoclide/coc-rls', { 'run': 'yarn install --frozen-lockfile' })
    call s:ctx.use('neoclide/coc-tsserver', { 'run': 'yarn install --frozen-lockfile' })
    call s:ctx.use('neoclide/coc-eslint', { 'run': 'yarn install --frozen-lockfile' })
    call s:ctx.use('neoclide/coc-prettier', { 'run': 'yarn install --frozen-lockfile' })
    call s:ctx.use('neoclide/coc-snippets', { 'run': 'yarn install --frozen-lockfile' })
    call s:ctx.use('neoclide/coc-json', { 'run': 'yarn install --frozen-lockfile' })
    call s:ctx.use('neoclide/coc-html', { 'run': 'yarn install --frozen-lockfile' })
    call s:ctx.use('neoclide/coc-emmet', { 'run': 'yarn install --frozen-lockfile' })
    call s:ctx.use('neoclide/coc-css', { 'run': 'yarn install --frozen-lockfile' })
    call s:ctx.use('fannheyward/coc-pyright', { 'run': 'yarn install --frozen-lockfile' })
    " call s:ctx.use('iamcco/coc-vimlsp', { 'run': 'yarn install --frozen-lockfile' })
    call s:ctx.use('dag/vim2hs')
    call s:ctx.use('norcalli/nvim-colorizer.lua')
    if g:vim_ide_treesitter
      call s:ctx.use('nvim-treesitter/nvim-treesitter', { 'run': ':TSUpdate' })
    endif
  endif
" }}}
