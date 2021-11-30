" COUNTERHACK: Don't invent plugin manager abstraction layers anymore.

let s:plug = function('dotfiles#plugman#register')

" Files {{{
  call s:plug('https://github.com/tpope/vim-eunuch')
  if g:vim_ide
    call s:plug('https://github.com/francoiscabrol/ranger.vim')
  endif
" }}}

" Editing {{{
  if g:vim_ide
    " call s:plug('https://github.com/easymotion/vim-easymotion')
    call s:plug('https://github.com/junegunn/vim-easy-align')
  endif
  call s:plug('https://github.com/Raimondi/delimitMate')
  call s:plug('https://github.com/tpope/vim-repeat')
  call s:plug('https://github.com/tomtom/tcomment_vim')
  call s:plug('https://github.com/tpope/vim-surround')
  if !has('nvim-0.5.0')
    call s:plug('https://github.com/Yggdroot/indentLine')
  elseif !g:dotfiles_sane_indentline_enable
    " Doesn't use concealed text, can put indent guides on blank lines, depends
    " on <https://github.com/neovim/neovim/pull/13952/files>, backwards
    " compatible with the original indentLine (in terms of options). Must be
    " later than v2.1.0 due to fix of a critical bug in
    " <https://github.com/lukas-reineke/indent-blankline.nvim/pull/155>.
    call s:plug('https://github.com/lukas-reineke/indent-blankline.nvim')
  endif
  call s:plug('https://github.com/henrik/vim-indexed-search')
  call s:plug('https://github.com/andymass/vim-matchup')
  call s:plug('https://github.com/inkarkat/vim-ingo-library')
  call s:plug('https://github.com/inkarkat/vim-LineJuggler', { 'branch': 'stable' })
  call s:plug('https://github.com/reedes/vim-pencil')
  call s:plug('https://github.com/tommcdo/vim-exchange')
  call s:plug('https://github.com/justinmk/vim-sneak')
" }}}

" Text objects {{{
  call s:plug('https://github.com/kana/vim-textobj-user')
  call s:plug('https://github.com/kana/vim-textobj-entire')
  call s:plug('https://github.com/kana/vim-textobj-line')
  call s:plug('https://github.com/kana/vim-textobj-indent')
  call s:plug('https://github.com/glts/vim-textobj-comment')
" }}}

" UI {{{
  call s:plug('https://github.com/moll/vim-bbye')
  call s:plug('https://github.com/gerw/vim-HiLinkTrace')
  call s:plug('https://github.com/vim-airline/vim-airline')
  call s:plug('https://github.com/tpope/vim-obsession')
  call s:plug('https://github.com/romainl/vim-qf')
" }}}

" Git {{{
  if g:vim_ide
    call s:plug('https://github.com/tpope/vim-fugitive')
    call s:plug('https://github.com/tpope/vim-rhubarb')
    call s:plug('https://github.com/mhinz/vim-signify', (has('nvim') || has('patch-8.0.902')) ? {} : { 'branch': 'legacy' })
    " call s:plug('https://github.com/airblade/vim-gitgutter')
  endif
" }}}

" FZF {{{
  call s:plug('https://github.com/junegunn/fzf', { 'do': './install --bin' })
  call s:plug('https://github.com/junegunn/fzf.vim')
" }}}

" Programming {{{
  let g:polyglot_disabled = get(g:, 'polyglot_disabled', []) + ['sensible']
  call s:plug('https://github.com/sheerun/vim-polyglot')
  call s:plug('https://github.com/chikamichi/mediawiki.vim')
  call s:plug('https://github.com/ron-rs/ron.vim')
  call s:plug('https://github.com/kylelaker/riscv.vim')
  if g:vim_ide
    if exists('*luaeval') && luaeval('vim.loop ~= nil')
      call s:plug('https://github.com/nanotee/luv-vimdocs', { 'branch': 'main' })
    endif
    if has('nvim-0.5.0') && get(g:, 'dotfiles_new_completion', 0)
      call s:plug('https://github.com/neovim/nvim-lspconfig')
      " call s:plug('https://github.com/hrsh7th/nvim-compe')
      call s:plug('https://github.com/hrsh7th/vim-vsnip')
      call s:plug('https://github.com/hrsh7th/nvim-cmp', { 'branch': 'main' })
      call s:plug('https://github.com/hrsh7th/cmp-nvim-lsp', { 'branch': 'main' })
      call s:plug('https://github.com/hrsh7th/cmp-nvim-lua', { 'branch': 'main' })
      call s:plug('https://github.com/hrsh7th/cmp-buffer', { 'branch': 'main' })
      call s:plug('https://github.com/f3fora/cmp-spell')
      call s:plug('https://github.com/hrsh7th/cmp-path', { 'branch': 'main' })
      call s:plug('https://github.com/hrsh7th/cmp-vsnip', { 'branch': 'main' })
    elseif g:dotfiles_build_coc_from_source
      call s:plug('https://github.com/neoclide/coc.nvim', { 'branch': 'master', 'do': 'yarn install --frozen-lockfile' })
      call s:plug('https://github.com/fannheyward/coc-rust-analyzer', { 'do': 'yarn install --frozen-lockfile' })
      " call s:plug('https://github.com/neoclide/coc-rls', { 'do': 'yarn install --frozen-lockfile' })
      call s:plug('https://github.com/neoclide/coc-tsserver', { 'do': 'yarn install --frozen-lockfile' })
      call s:plug('https://github.com/neoclide/coc-eslint', { 'do': 'yarn install --frozen-lockfile' })
      call s:plug('https://github.com/neoclide/coc-prettier', { 'do': 'yarn install --frozen-lockfile' })
      call s:plug('https://github.com/neoclide/coc-snippets', { 'do': 'yarn install --frozen-lockfile' })
      call s:plug('https://github.com/neoclide/coc-json', { 'do': 'yarn install --frozen-lockfile' })
      call s:plug('https://github.com/neoclide/coc-html', { 'do': 'yarn install --frozen-lockfile' })
      call s:plug('https://github.com/neoclide/coc-emmet', { 'do': 'yarn install --frozen-lockfile' })
      call s:plug('https://github.com/neoclide/coc-css', { 'do': 'yarn install --frozen-lockfile' })
      call s:plug('https://github.com/fannheyward/coc-pyright', { 'do': 'yarn install --frozen-lockfile' })
      " call s:plug('https://github.com/iamcco/coc-vimlsp', { 'do': 'yarn install --frozen-lockfile' })
    else
      call s:plug('https://github.com/neoclide/coc.nvim', { 'branch': 'release' })
    endif
    call s:plug('https://github.com/norcalli/nvim-colorizer.lua')
  endif
" }}}
