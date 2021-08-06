" COUNTERHACK: Don't invent plugin manager abstraction layers anymore.

let s:plug = function('dotfiles#plugman#register')

" Files {{{
  call s:plug('tpope/vim-eunuch')
  if g:vim_ide
    call s:plug('francoiscabrol/ranger.vim')
  endif
" }}}

" Editing {{{
  if g:vim_ide
    " call s:plug('easymotion/vim-easymotion')
    call s:plug('junegunn/vim-easy-align')
  endif
  call s:plug('Raimondi/delimitMate')
  call s:plug('tpope/vim-repeat')
  call s:plug('tomtom/tcomment_vim')
  call s:plug('tpope/vim-surround')
  " if has('nvim-0.5.0')
  "   " Doesn't use concealed text, can put indent guides on blank lines, depends
  "   " on <https://github.com/neovim/neovim/pull/13952/files>, backwards
  "   " compatible with the original indentLine (in terms of options). ...And has
  "   " a critical bug:
  "   " <https://github.com/lukas-reineke/indent-blankline.nvim/issues/51>
  "   call s:plug('lukas-reineke/indent-blankline.nvim')
  " else
    call s:plug('Yggdroot/indentLine')
  " endif
  call s:plug('henrik/vim-indexed-search')
  call s:plug('andymass/vim-matchup')
  call s:plug('inkarkat/vim-ingo-library')
  call s:plug('inkarkat/vim-LineJuggler', { 'branch': 'stable' })
  call s:plug('reedes/vim-pencil')
  call s:plug('tommcdo/vim-exchange')
  call s:plug('justinmk/vim-sneak')
" }}}

" Text objects {{{
  call s:plug('kana/vim-textobj-user')
  call s:plug('kana/vim-textobj-entire')
  call s:plug('kana/vim-textobj-line')
  call s:plug('kana/vim-textobj-indent')
  call s:plug('glts/vim-textobj-comment')
" }}}

" UI {{{
  call s:plug('moll/vim-bbye')
  call s:plug('gerw/vim-HiLinkTrace')
  call s:plug('vim-airline/vim-airline')
  call s:plug('tpope/vim-obsession')
  call s:plug('romainl/vim-qf')
" }}}

" Git {{{
  if g:vim_ide
    call s:plug('tpope/vim-fugitive')
    call s:plug('tpope/vim-rhubarb')
    call s:plug('mhinz/vim-signify', (has('nvim') || has('patch-8.0.902')) ? {} : { 'branch': 'legacy' })
    " call s:plug('airblade/vim-gitgutter')
  endif
" }}}

" FZF {{{
  call s:plug('junegunn/fzf', { 'do': './install --bin' })
  call s:plug('junegunn/fzf.vim')
" }}}

" Programming {{{
  let g:polyglot_disabled = ['sensible']
  call s:plug('sheerun/vim-polyglot')
  call s:plug('chikamichi/mediawiki.vim')
  call s:plug('ron-rs/ron.vim')
  call s:plug('kylelaker/riscv.vim')
  call s:plug('dag/vim2hs')
  if g:vim_ide
    call s:plug('neoclide/coc.nvim', { 'branch': 'master', 'do': 'yarn install --frozen-lockfile' })
    call s:plug('fannheyward/coc-rust-analyzer', { 'do': 'yarn install --frozen-lockfile' })
    " call s:plug('neoclide/coc-rls', { 'do': 'yarn install --frozen-lockfile' })
    call s:plug('neoclide/coc-tsserver', { 'do': 'yarn install --frozen-lockfile' })
    call s:plug('neoclide/coc-eslint', { 'do': 'yarn install --frozen-lockfile' })
    call s:plug('neoclide/coc-prettier', { 'do': 'yarn install --frozen-lockfile' })
    call s:plug('neoclide/coc-snippets', { 'do': 'yarn install --frozen-lockfile' })
    call s:plug('neoclide/coc-json', { 'do': 'yarn install --frozen-lockfile' })
    call s:plug('neoclide/coc-html', { 'do': 'yarn install --frozen-lockfile' })
    call s:plug('neoclide/coc-emmet', { 'do': 'yarn install --frozen-lockfile' })
    call s:plug('neoclide/coc-css', { 'do': 'yarn install --frozen-lockfile' })
    call s:plug('fannheyward/coc-pyright', { 'do': 'yarn install --frozen-lockfile' })
    " call s:plug('iamcco/coc-vimlsp', { 'do': 'yarn install --frozen-lockfile' })
    call s:plug('norcalli/nvim-colorizer.lua')
  endif
" }}}
