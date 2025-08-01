" All plugin definitions are written as links to github.com (instead of the
" typical `user/repo`) so that I can move the cursor over any and press `gx`.

exe dotplug#define_plug_here()

" Files {{{
  " Useful filesystem command wrappers: `:Rename`, `:Delete`, `:Chmod` etc.
  Plug 'https://github.com/tpope/vim-eunuch'
  " Modelines have caused several arbitrary code execution vulnerabilities over
  " the years, see <https://security.stackexchange.com/a/157739>.
  Plug 'https://github.com/ypcrts/securemodelines'
" }}}

" Editing {{{
  " Automatic tabular alignment of text. A pretty complicated plugin to use.
  Plug 'https://github.com/junegunn/vim-easy-align'
  " Inserts closing quotes/parens/brackets/braces when typing an opening one.
  " Also handles <Space> or <Enter> being pressed within a pair of those
  " delimiters.
  Plug 'https://github.com/Raimondi/delimitMate'
  " A library which allows plugins to create mappings repeatable with the dot
  " command.
  Plug 'https://github.com/tpope/vim-repeat'
  " For commenting out code. I prefer this one to tpope's vim-commentary
  " because it handles embedded languages (e.g.: JS within HTML), places
  " comment markers on empty lines when multiple paragraphs of code are
  " selected and has a mapping for adding block comments specifically.
  Plug 'https://github.com/tomtom/tcomment_vim'
  " Adds a bunch of operators that should really be built-in to Vim: wrap text
  " in parentheses, quotes or even XML tags with `ys`, delete the surrounding
  " delimiters with `ds` and change them with `cs`.
  Plug 'https://github.com/tpope/vim-surround'
  " Draws indentation guides like in normie text editors. My configs also
  " include my own Lua implementation of this plugin, the Original is used only
  " when the former is not available.
  Plug 'https://github.com/Yggdroot/indentLine', { 'if': !has('nvim-0.5.0') }
  " Prints the number of search results when using the `/` command or the `n`
  " and `N` motions and similar.
  Plug 'https://github.com/henrik/vim-indexed-search', { 'if': !exists('*searchcount') }
  " Extension of the built-in matchit plugin (highlights matching braces,
  " typically for blocks in syntaxes of C-like languages) and the `%` family of
  " motions (jump between those block delimiters), which adds support for
  " languages which use English keywords for delimiting blocks (Vimscript, Lua,
  " Ruby etc).
  Plug 'https://github.com/andymass/vim-matchup'
  " Adds commands for inserting and moving around nearby lines: `[e` and `]e`
  " for swapping two lines, `]<Space>` and `[<Space>` for inserting blank ones.
  " Also adds many more useful (URL and XML encoding/decoding of selection, for
  " instance) and useless utilities.
  Plug 'https://github.com/tpope/vim-unimpaired'
  " Adds an operator `cx` for swapping two text selections. Occasionally VERY
  " useful, especially during refactoring for changing the order of arguments
  " in a function.
  Plug 'https://github.com/tommcdo/vim-exchange'
  " Creates a simple ("powerful, reliable, yet minimal" indeed!) motion on the
  " keys `s` (forwards) and `S` (backwards) which is a logical continuation of
  " the built-in `f` `F` `t` `T` motions. This motion simply uses two keys for
  " navigation instead of a single one: apparently, pairs of characters can
  " become unique enough in code files for this method is viable for jumping
  " over entire pages of code (with a few presses of `;`, granted). Also
  " highlights the matches for the aforementioned built-in motions. I prefer it
  " to EasyMotion[1].
  " [1]: <https://github.com/easymotion/vim-easymotion>
  Plug 'https://github.com/justinmk/vim-sneak'
  " Shows a diff between two selected ranges of lines, or Git conflict markers.
  " Discovered this one thanks to TJ[1].
  " [1]: <https://github.com/tjdevries/config_manager/blob/1b7d2f60ed6685022e29c1bdef2625bb7856e1eb/xdg_config/nvim/lua/tj/plugins.lua#L604>
  Plug 'https://github.com/AndrewRadev/linediff.vim'
  " Automatically close XML/HTML/JSX tags.
  Plug 'https://github.com/alvan/vim-closetag'
  " Automatic indentation detection.
  Plug 'https://github.com/tpope/vim-sleuth'
" }}}

" Text objects {{{
  " Library for creating custom text objects.
  Plug 'https://github.com/kana/vim-textobj-user'
  " Entire contents of the buffer - `ae` and `ie`.
  Plug 'https://github.com/kana/vim-textobj-entire', { 'requires': 'vim-textobj-user' }
  " A single line - `al` (with indentation) and `il` (without indentation).
  Plug 'https://github.com/kana/vim-textobj-line', { 'requires': 'vim-textobj-user' }
  " This one is really handy: a code block determined by indentation (when it
  " is the same or more indented) - `ai` (include blank lines) and `ii`
  " (exclude blanks, selecting a single paragraph).
  Plug 'https://github.com/kana/vim-textobj-indent', { 'requires': 'vim-textobj-user' }
  " Selects a comment block - `ic` and `ac` (not sure what is the difference).
  " Useful for reformatting comments with `gcgc` (a mapping of `gc` to `ac`
  " exists for compatibility with vim-commentary).
  Plug 'https://github.com/glts/vim-textobj-comment', { 'requires': 'vim-textobj-user' }
" }}}

" UI {{{
  " Debugging utility for colorschemes. Prints the hlgroups, synstack and (most
  " importantly) the chain of hlgroup links with `:HLT` or `<leader>hlt`.
  Plug 'https://github.com/gerw/vim-HiLinkTrace', { 'if': !has('nvim-0.9.0') }
  " A very fancy and modular statusline (not exactly "light as air", though).
  Plug 'https://github.com/vim-airline/vim-airline'
  " Automatically re-saves sessions created with `:mksession`.
  Plug 'https://github.com/tpope/vim-obsession'
  " Various nifty utilities for quickfix and location lists. This plugin is
  " responsible for auto-opening the lists after commands like :grep and :make.
  Plug 'https://github.com/romainl/vim-qf'
  " More niceties for quickfix/loclists: file preview, filtering with FZF etc.
  Plug 'https://github.com/kevinhwang91/nvim-bqf', { 'if': has('nvim-0.6.1') }
" }}}

" Git {{{
  if g:vim_ide
    " A very, very high-quality UI for Git.
    Plug 'https://github.com/tpope/vim-fugitive'
    " Support for GitHub and GitLab (`:GBrowse`, ticket autocomplete in
    " `.git/COMMIT_EDITMSG`).
    Plug 'https://github.com/tpope/vim-rhubarb', { 'requires': 'vim-fugitive' }
    Plug 'https://github.com/shumphrey/fugitive-gitlab.vim', { 'requires': 'vim-fugitive' }
    " Show change markers (relative to what is in the Git repository) in the
    " sign column. vim-gitgutter is a bit slow and creates lots of temporary
    " files with `tempname()` (and then doesn't delete them), but vim-signify
    " flashes between results of `git diff` and `git diff --staged` when the
    " file is staged.
    if has('nvim-0.9.0')
      Plug 'https://github.com/lewis6991/gitsigns.nvim'
    elseif has('nvim') || has('patch-8.0.902')
      Plug 'https://github.com/mhinz/vim-signify'
    else
      Plug 'https://github.com/airblade/vim-gitgutter'
    endif
  endif
" }}}

" FZF {{{
  " The core library for integration calling fzf from Vim (also handles
  " installation of fzf when it's not already available on the system).
  Plug 'https://github.com/junegunn/fzf', { 'do': './install --bin' }
  if g:vim_ide == 2
    Plug 'https://github.com/folke/snacks.nvim', { 'if': has('nvim-0.9.4') }
    Plug 'https://github.com/ibhagwan/fzf-lua', { 'if': has('nvim-0.9.0'), 'requires': 'fzf' }
  else
    " All of the end-user commands for using fzf on everything: `:Files`,
    " `:Buffers`, `:Helptags`, `:Commands` and so on.
    Plug 'https://github.com/junegunn/fzf.vim', { 'requires': 'fzf' }
  endif
" }}}

" Language packs {{{
  " NOTE: I've been using vim-polyglot previously, which is a giant collection
  " of syntax packs and language-specific plugins. However, it has not been
  " updated for a long time, it required some hacks to make it work properly,
  " it cannot be integrated with the new Lua filetype detection system in Nvim,
  " plus a lot of syntax packs have been absorbed by Vim and Neovim over time.
  " So, instead of using the giant and clumsy vim-polyglot, I will include a
  " handful of language packs that I actually need, whether it is because they
  " are better than those in `$VIMRUNTIME` or have not been bundled with Vim
  " yet. In any case, a good list of language packs can be found here:
  " <https://github.com/sheerun/vim-polyglot#language-packs>

  " I like these much better than Vim's and Nvim's default ones:
  Plug 'https://github.com/tbastos/vim-lua'
  Plug 'https://github.com/raymond-w-ko/vim-lua-indent'
  Plug 'https://github.com/plasticboy/vim-markdown'
  Plug 'https://github.com/vim-python/python-syntax'
  " (this one highlights function invocations which the default one does not do)
  Plug 'https://github.com/bfrg/vim-cpp-modern'
  " The indenting script here is just so much better than the default one.
  " Discovered this plugin thanks to vim-polyglot.
  Plug 'https://github.com/Vimjas/vim-python-pep8-indent'

  " JavaScript and TypeScript development:
  Plug 'https://github.com/pangloss/vim-javascript'
  " TypeScript evolves faster than Vim updates are released, so I include this
  " plugin instead of relying on its copy upstreamed into Vim. Great username btw.
  Plug 'https://github.com/HerringtonDarkholme/yats.vim'
  "     \ { 'if': !has('nvim-0.4.0') && !has('patch-8.1.1486') }
  " For some reason, `$VIMRUNTIME` includes support only for TSX out of the
  " box, but not for JSX. By default, JSX filetype is just an alias for JS.
  Plug 'https://github.com/MaxMEllon/vim-jsx-pretty'

  " The Rust language pack bundled with Vim has not been outdated for a long
  " time[1], plus this is an official plugin and it's super good.
  " [1]: <https://github.com/vim/vim/pull/13075>
  Plug 'https://github.com/rust-lang/rust.vim'

  " Sysadmin stuff:
  Plug 'https://github.com/MTDL9/vim-log-highlighting'
  " I actually got so used to this one since it was included with vim-polyglot,
  " while the `$VIMRUNTIME` just uses plain `dosini` for systemd configs.
  Plug 'https://github.com/wgwoods/vim-systemd-syntax'
  Plug 'https://github.com/tpope/vim-git'
  Plug 'https://github.com/chr4/nginx.vim', { 'if': !has('nvim-0.6.0') && !has('patch-8.2.3474') }

  " Some niche languages that were not included with Vim until recently:
  Plug 'https://github.com/tikhomirov/vim-glsl', { 'if': !has('nvim-0.11.0') && !has('patch-9.1.0610') }
  Plug 'https://github.com/cespare/vim-toml', { 'if': !has('nvim-0.6.0') && !has('patch-8.2.3520') }
  Plug 'https://github.com/cakebaker/scss-syntax.vim', { 'if': !has('nvim-0.5.0') && !has('patch-8.1.2397') }

  " An alternative optimized filetype detection system. No longer required as it
  " was integrated into the Neovim core in v0.7.0:
  " <https://github.com/neovim/neovim/commit/3fd454bd4a6ceb1989d15cf2d3d5e11d7a253b2d>
  Plug 'https://github.com/nathom/filetype.nvim', {
        \ 'branch': 'main', 'if': has('nvim-0.5.0') && !has('nvim-0.7.0') }
" }}}

" Programming {{{
  if g:vim_ide
    " Asynchronous task runner. Old, but gold.
    Plug 'https://github.com/tpope/vim-dispatch'
    " An interactive Lua playground.
    Plug 'https://github.com/rafcamlet/nvim-luapad', { 'if': has('nvim-0.5.0') }
    " A debugger for Lua scripts running in Neovim itself.
    Plug 'https://github.com/jbyuki/one-small-step-for-vimkind', { 'if': has('nvim-0.7.0') }
    " The old and trusty coc.nvim. For Vim/Neovim version requirements, see [1].
    " [1]: <https://github.com/neoclide/coc.nvim/blob/a9ab3e4885bc8ed0aa38c5a8ee5953b0a7bc9bd3/plugin/coc.vim#L11-L15>
    Plug 'https://github.com/neoclide/coc.nvim', { 'branch': 'release',
          \ 'if': g:vim_ide == 1 && (has('patch-9.0.0438') || has('nvim-0.8.0')) }
    " A client for the Debug Adapter Protocol (and a perfect candidate for lazy-loading!).
    Plug 'https://github.com/puremourning/vimspector', { 'lazy': v:true,
          \ 'if': has('nvim') ? has('nvim-0.4.3') : (v:version >= 802 && has('python3')) }
    if g:vim_ide == 2 && has('nvim-0.11')
      " Used for setting up non-LSP formatters (but makes improvements to LSP formatting as well).
      Plug 'https://github.com/stevearc/conform.nvim'
      " Shows LSP and non-LSP notifications and progress messages in a nice and unobtrusive UI.
      Plug 'https://github.com/j-hui/fidget.nvim'
      " A bag of configs for Language Servers.
      Plug 'https://github.com/neovim/nvim-lspconfig', { 'setup': 'let g:lspconfig = 1' }
      " Provides JSON and YAML schemas.
      Plug 'https://github.com/b0o/SchemaStore.nvim'
      " Manages global and local settings for Language Servers.
      Plug 'https://github.com/folke/neoconf.nvim'
    endif
    if has('nvim-0.9.0')
      " The new parsing and syntax highlighting system for Neovim.
      Plug 'https://github.com/nvim-treesitter/nvim-treesitter', { 'do': ':TSUpdate' }
      Plug 'https://github.com/nvim-treesitter/nvim-treesitter-textobjects', { 'requires': 'nvim-treesitter' }
    endif
  endif
" }}}

delcommand Plug
