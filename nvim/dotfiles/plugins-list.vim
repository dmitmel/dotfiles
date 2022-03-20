" NOTE: Don't invent plugin manager abstraction layers anymore.
let s:plug = function('dotfiles#plugman#register')

" All plugin definitions are written as links to github.com (instead of the
" typical `user/repo`) so that I can move the cursor over any and press `gx`.

" General-purpose libraries {{{
  if has('nvim-0.5.0')
    " Required by:
    " 1. gitsigns.nvim
    call s:plug('https://github.com/nvim-lua/plenary.nvim')
  endif
" }}}

" Files {{{
  " Useful filesystem command wrappers: `:Rename`, `:Delete`, `:Chmod` etc.
  call s:plug('https://github.com/tpope/vim-eunuch')
  " Superficial integration between Vim and the Ranger file manager[1], I only
  " use it for exploring the project (this idea was taken from the classic "oil
  " and vinegar" article[2]). Pressing `<leader>o` pops up the explorer in the
  " parent directory of the current buffer.
  " [1]: <https://ranger.github.io/>
  " [2}: <http://vimcasts.org/blog/2013/01/oil-and-vinegar-split-windows-and-project-drawer/>
  call s:plug('https://github.com/francoiscabrol/ranger.vim')
" }}}

" Editing {{{
  " Automatic tabular alignment of text. A pretty complicated plugin to use.
  call s:plug('https://github.com/junegunn/vim-easy-align')
  " Inserts closing quotes/parens/brackets/braces when typing an opening one.
  " Also handles <Space> or <Enter> being pressed within a pair of those
  " delimiters.
  call s:plug('https://github.com/Raimondi/delimitMate')
  " A library which allows plugins to create mappings repeatable with the dot
  " command.
  call s:plug('https://github.com/tpope/vim-repeat')
  " For commenting out code. I prefer this one to tpope's vim-commentary
  " because it handles embedded languages (e.g.: JS within HTML), places
  " comment markers on empty lines when multiple paragraphs of code are
  " selected and has a mapping for adding block comments specifically.
  call s:plug('https://github.com/tomtom/tcomment_vim')
  " Adds a bunch of operators that should really be built-in to Vim: wrap text
  " in parentheses, quotes or even XML tags with `ys`, delete the surrounding
  " delimiters with `ds` and change them with `cs`.
  call s:plug('https://github.com/tpope/vim-surround')
  " The following block selects between varying implementations of plugins for
  " drawing indentation guides like in those IDEs (even Notepad++ has them!).
  " Note that my configs also include an implementation - the "sane indentLine"
  " plugin.
  if !has('nvim-0.5.0')
    " "The Original".
    call s:plug('https://github.com/Yggdroot/indentLine')
  elseif !g:dotfiles_sane_indentline_enable
    " Doesn't use concealed text, can put indent guides on blank lines, depends
    " this neovim PR[1] merged in v0.5.0, backwards compatible with the
    " original indentLine (in terms of options). Must be later than v2.1.0 due
    " to fix of a critical bug[2].
    " [1]: <https://github.com/neovim/neovim/pull/13952>
    " [2]: <https://github.com/lukas-reineke/indent-blankline.nvim/pull/155>
    call s:plug('https://github.com/lukas-reineke/indent-blankline.nvim')
  endif
  if !exists('*searchcount')
    " Prints the number of search results when using the `/` command or the `n`
    " and `N` motions and similar.
    call s:plug('https://github.com/henrik/vim-indexed-search')
  endif
  " Extension of the built-in matchit plugin (highlights matching braces,
  " typically for blocks in syntaxes of C-like languages) and the `%` family of
  " motions (jump between those block delimiters), which adds support for
  " languages which use English keywords for delimiting blocks (Vimscript, Lua,
  " Ruby etc).
  call s:plug('https://github.com/andymass/vim-matchup')
  " Adds commands for inserting and moving around nearby lines: `[e` and `]e`
  " for swapping two lines, `]<Space>` and `[<Space>` for inserting blank ones.
  " Also adds many more useful (URL and XML encoding/decoding of selection, for
  " instance) and useless utilities.
  call s:plug('https://github.com/tpope/vim-unimpaired')
  " Sets up quite a few defaults for straightforward prose writing in Vim. Just
  " read its README for the set of features.
  call s:plug('https://github.com/reedes/vim-pencil')
  " Adds an operator `cx` for swapping two text selections. Occasionally VERY
  " useful, especially during refactoring for changing the order of arguments
  " in a function.
  call s:plug('https://github.com/tommcdo/vim-exchange')
  " Creates a simple ("powerful, reliable, yet minimal" indeed!) motion on the
  " keys `s` (forwards) and `S` (backwards) which is a logical continuation of
  " the built-in `f` `F` `t` `T` motions. This motion simply uses two keys for
  " navigation instead of a single one: apparently, pairs of characters can
  " become unique enough in code files for this method is viable for jumping
  " over entire pages of code (with a few presses of `;`, granted). Also
  " highlights the matches for the aforementioned built-in motions. I prefer it
  " to EasyMotion[1].
  " [1]: <https://github.com/easymotion/vim-easymotion>
  call s:plug('https://github.com/justinmk/vim-sneak')
  " Shows a diff between two selected ranges of lines, or Git conflict markers.
  " Discovered this one thanks to TJ[1].
  " [1]: <https://github.com/tjdevries/config_manager/blob/1b7d2f60ed6685022e29c1bdef2625bb7856e1eb/xdg_config/nvim/lua/tj/plugins.lua#L604>
  call s:plug('https://github.com/AndrewRadev/linediff.vim')
  " Automatically close XML/HTML/JSX tags.
  call s:plug('https://github.com/alvan/vim-closetag')
" }}}

" Text objects {{{
  " Library for creating custom text objects.
  call s:plug('https://github.com/kana/vim-textobj-user')
  " Entire contents of the buffer - `ae` and `ie`.
  call s:plug('https://github.com/kana/vim-textobj-entire')
  " A single line - `al` (with indentation) and `il` (without indentation).
  call s:plug('https://github.com/kana/vim-textobj-line')
  " This one is really handy: a code block determined by indentation (when it
  " is the same or more indented) - `ai` (include blank lines) and `ii`
  " (exclude blanks, selecting a single paragraph).
  call s:plug('https://github.com/kana/vim-textobj-indent')
  " Selects a comment block - `ic` and `ac` (not sure what is the difference).
  " Useful for reformatting comments with `gcgc` (a mapping of `gc` to `ac`
  " exists for compatibility with vim-commentary).
  call s:plug('https://github.com/glts/vim-textobj-comment')
" }}}

" UI {{{
  " Closes buffers the way you would expect - that is, without closing windows.
  call s:plug('https://github.com/moll/vim-bbye')
  " Debugging utility for colorschemes. Prints the hlgroups, synstack and (most
  " importantly) the chain of hlgroup links with `:HLT` or `<leader>hlt`.
  call s:plug('https://github.com/gerw/vim-HiLinkTrace')
  " A very fancy and modular statusline (not exactly "light as air", though).
  call s:plug('https://github.com/vim-airline/vim-airline')
  " Automatically re-saves sessions created with `:mksession`.
  call s:plug('https://github.com/tpope/vim-obsession')
  " Various nifty utilities for quickfix and location lists.
  call s:plug('https://github.com/romainl/vim-qf')
" }}}

" Git {{{
  if g:vim_ide
    " A very, very high-quality UI for Git.
    call s:plug('https://github.com/tpope/vim-fugitive')
    " Support for GitHub and GitLab (`:GBrowse`, ticket autocomplete in
    " `.git/COMMIT_EDITMSG`).
    call s:plug('https://github.com/tpope/vim-rhubarb')
    call s:plug('https://github.com/shumphrey/fugitive-gitlab.vim')
    " Show change markers (relative to what is in the Git repository) in the
    " sign column. vim-gitgutter is a bit slow and creates lots of temporary
    " files with `tempname()` (and then doesn't delete them), but vim-signify
    " flashes between results of `git diff` and `git diff --staged` when the
    " file is staged.
    if has('nvim-0.5.0')
      call s:plug('https://github.com/lewis6991/gitsigns.nvim')
    elseif has('nvim') || has('patch-8.0.902')
      call s:plug('https://github.com/mhinz/vim-signify')
    else
      call s:plug('https://github.com/airblade/vim-gitgutter')
    endif
  endif
" }}}

" FZF {{{
  " The core library for integration calling fzf from Vim (also handles
  " installation of fzf when it's not already available on the system).
  call s:plug('https://github.com/junegunn/fzf', { 'do': './install --bin' })
  " All of the end-user commands for using fzf on everything: `:Files`,
  " `:Buffers`, `:Helptags`, `:Commands` and so on.
  call s:plug('https://github.com/junegunn/fzf.vim')
" }}}

" Programming {{{
  " Automatic indentation detection.
  call s:plug('https://github.com/tpope/vim-sleuth')
  " A gigantic collection of syntax, ftplugin, indent, ftdetect etc scripts for
  " a lot of programming languages (the entire list[1]). Also bundles
  " vim-sensible[2] and vim-sleuth[3].
  " [1]: <https://github.com/sheerun/vim-polyglot#language-packs>
  " [2]: <https://github.com/tpope/vim-sensible>
  " [3]: <https://github.com/tpope/vim-sleuth>
  call s:plug('https://github.com/sheerun/vim-polyglot')
  let g:polyglot_disabled = get(g:, 'polyglot_disabled', [])
  " I disable the bundled version of vim-sensible because I define those
  " settings myself.
  call add(g:polyglot_disabled, 'sensible')
  " Bundled vim-sleuth is disabled because the upstream has more features and
  " requires less hacks to work with my setup.
  call add(g:polyglot_disabled, 'autoindent')
  " Highlighting of mediawiki markup. Installed while I was working on
  " <https://wiki.c2dl.info/>.
  call s:plug('https://github.com/chikamichi/mediawiki.vim')
  " Highlighting of RISC-V assembly keywords. The only reason I have this
  " installed is <https://github.com/dmitmel/riscv-playground>.
  call s:plug('https://github.com/kylelaker/riscv.vim')
  if g:vim_ide
    " The Lua standard library has been introduced in nvim 0.4.0, see
    " <https://github.com/neovim/neovim/commit/e2cc5fe09d98ce1ccaaa666a835c896805ccc196>.
    if has('nvim-0.4.0')
      " Reference manual of Lua 5.1 as a vimdoc file. <https://www.lua.org/manual/5.1/>
      call s:plug('https://github.com/bfredl/luarefvim')
      " Type declaration files for the Lua Language Server[1] of Nvim's Lua
      " APIs (actually includes other stuff, such as a pre-made configuration
      " for sumneko_lua[1], but that is opt-in due to the nature of Lua-based
      " plugins).
      " [1]: <https://github.com/sumneko/lua-language-server>
      " call s:plug('https://github.com/folke/lua-dev.nvim')
      " Mirror of the luv[1] documentation as a vimdoc file. <https://github.com/luvit/luv/blob/master/docs.md>
      call s:plug('https://github.com/nanotee/luv-vimdocs', { 'branch': 'main' })
    endif
    " The built-in LSP client has been introduced in nvim 0.5.0, see
    " <https://github.com/neovim/neovim/commit/a5ac2f45ff84a688a09479f357a9909d5b914294>.
    if has('nvim-0.5.0') && get(g:, 'dotfiles_use_nvimlsp', 0)
      " Collection of pre-made Language Server configs for Neovim's built-in
      " LSP client. Only defines stuff like names of executables of the
      " Servers, default settings and initializationOptions, workspace root
      " dir patterns etc. Might get rid of this soon.
      call s:plug('https://github.com/neovim/nvim-lspconfig')
      " The current snippet expansion plugin. Doesn't contain any snippet
      " libraries of its own.
      call s:plug('https://github.com/dcampos/nvim-snippy')
      " The current completion plugin.
      call s:plug('https://github.com/hrsh7th/nvim-cmp', { 'branch': 'main' })
      " The following plugins are actually completion sources for nvim-cmp:
      " The built-in Language Server client.
      call s:plug('https://github.com/hrsh7th/cmp-nvim-lsp', { 'branch': 'main' })
      " Words from buffers (as I like to call them, the "dumb completions").
      call s:plug('https://github.com/hrsh7th/cmp-buffer', { 'branch': 'main' })
      " File paths.
      call s:plug('https://github.com/hrsh7th/cmp-path', { 'branch': 'main' })
      " Snippets registered in the snippet engine.
      call s:plug('https://github.com/dcampos/cmp-snippy')
    elseif g:dotfiles_build_coc_from_source
      " Plugins for the old completion-and-language-analysis system based
      " around coc.nvim.
      call s:plug('https://github.com/neoclide/coc.nvim', { 'branch': 'master', 'do': 'yarn install --frozen-lockfile' })
      " Port of <https://github.com/rust-analyzer/rust-analyzer/tree/master/editors/code>.
      call s:plug('https://github.com/fannheyward/coc-rust-analyzer', { 'do': 'yarn install --frozen-lockfile' })
      " Port of <https://github.com/microsoft/vscode/tree/main/extensions/typescript-language-features>.
      " <https://github.com/Microsoft/TypeScript/wiki/Standalone-Server-%28tsserver%29>
      call s:plug('https://github.com/neoclide/coc-tsserver', { 'do': 'yarn install --frozen-lockfile' })
      " Port of <https://github.com/Microsoft/vscode-eslint>.
      call s:plug('https://github.com/neoclide/coc-eslint', { 'do': 'yarn install --frozen-lockfile' })
      " Port of <https://github.com/prettier/prettier-vscode>.
      call s:plug('https://github.com/neoclide/coc-prettier', { 'do': 'yarn install --frozen-lockfile' })
      " The snippet engine. The core actually doesn't handle expansion of
      " snippets, so this is required even when not using snippet libraries
      " because Language Servers often respond with snippets in completion
      " results.
      call s:plug('https://github.com/neoclide/coc-snippets', { 'do': 'yarn install --frozen-lockfile' })
      " Port of <https://github.com/microsoft/vscode/tree/main/extensions/json-language-features>.
      call s:plug('https://github.com/neoclide/coc-json', { 'do': 'yarn install --frozen-lockfile' })
      " Port of <https://github.com/microsoft/vscode/tree/main/extensions/html-language-features>.
      call s:plug('https://github.com/neoclide/coc-html', { 'do': 'yarn install --frozen-lockfile' })
      " Port of <https://github.com/microsoft/vscode/tree/main/extensions/emmet>.
      call s:plug('https://github.com/neoclide/coc-emmet', { 'do': 'yarn install --frozen-lockfile' })
      " Port of <https://github.com/microsoft/vscode/tree/main/extensions/css-language-features>.
      call s:plug('https://github.com/neoclide/coc-css', { 'do': 'yarn install --frozen-lockfile' })
      " Port of <https://github.com/microsoft/pyright/tree/main/packages/vscode-pyright>.
      call s:plug('https://github.com/fannheyward/coc-pyright', { 'do': 'yarn install --frozen-lockfile' })
    else
      call s:plug('https://github.com/neoclide/coc.nvim', { 'branch': 'release' })
    endif
    if has('nvim-0.4.0')
      " Highlights colors written in different notations (`#rrggbb`, `rgb(r,g,b)`
      " etc, the typical CSS stuff) for quick preview.
      call s:plug('https://github.com/chrisbra/Colorizer')
    endif
  endif
" }}}
