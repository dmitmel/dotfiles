" All plugin definitions are written as links to github.com (instead of the
" typical `user/repo`) so that I can move the cursor over any and press `gx`.

exe dotplug#define_plug_here()

" Files {{{
  " Useful filesystem command wrappers: `:Rename`, `:Delete`, `:Chmod` etc.
  Plug 'https://github.com/tpope/vim-eunuch'
  " Superficial integration between Vim and the Ranger file manager[1], I only
  " use it for exploring the project (this idea was taken from the classic "oil
  " and vinegar" article[2]). Pressing `<leader>o` pops up the explorer in the
  " parent directory of the current buffer.
  " [1]: <https://ranger.github.io/>
  " [2}: <http://vimcasts.org/blog/2013/01/oil-and-vinegar-split-windows-and-project-drawer/>
  Plug 'https://github.com/francoiscabrol/ranger.vim'
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
  Plug 'https://github.com/tpope/vim-repeat', { 'priority': 100 }
  " For commenting out code. I prefer this one to tpope's vim-commentary
  " because it handles embedded languages (e.g.: JS within HTML), places
  " comment markers on empty lines when multiple paragraphs of code are
  " selected and has a mapping for adding block comments specifically.
  Plug 'https://github.com/tomtom/tcomment_vim'
  " Adds a bunch of operators that should really be built-in to Vim: wrap text
  " in parentheses, quotes or even XML tags with `ys`, delete the surrounding
  " delimiters with `ds` and change them with `cs`.
  Plug 'https://github.com/tpope/vim-surround'
  " The following block selects between varying implementations of plugins for
  " drawing indentation guides like in those IDEs (even Notepad++ has them!).
  " Note that my configs also include an implementation - the "sane indentLine"
  " plugin.
  if !has('nvim-0.5.0')
    " "The Original".
    Plug 'https://github.com/Yggdroot/indentLine'
  elseif !g:dotfiles_sane_indentline_enable
    " Doesn't use concealed text, can put indent guides on blank lines, depends
    " this neovim PR[1] merged in v0.5.0, backwards compatible with the
    " original indentLine (in terms of options). Must be later than v2.1.0 due
    " to fix of a critical bug[2].
    " [1]: <https://github.com/neovim/neovim/pull/13952>
    " [2]: <https://github.com/lukas-reineke/indent-blankline.nvim/pull/155>
    Plug 'https://github.com/lukas-reineke/indent-blankline.nvim'
  endif
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
  " Sets up quite a few defaults for straightforward prose writing in Vim. Just
  " read its README for the set of features.
  Plug 'https://github.com/reedes/vim-pencil'
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
  " Closes buffers the way you would expect - that is, without closing windows.
  Plug 'https://github.com/moll/vim-bbye'
  " Debugging utility for colorschemes. Prints the hlgroups, synstack and (most
  " importantly) the chain of hlgroup links with `:HLT` or `<leader>hlt`.
  Plug 'https://github.com/gerw/vim-HiLinkTrace', { 'if': !has('nvim-0.9.0') }
  " A very fancy and modular statusline (not exactly "light as air", though).
  Plug 'https://github.com/vim-airline/vim-airline'
  " Automatically re-saves sessions created with `:mksession`.
  Plug 'https://github.com/tpope/vim-obsession'
  " Various nifty utilities for quickfix and location lists.
  Plug 'https://github.com/romainl/vim-qf'
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
    if has('nvim-0.5.0')
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
  " All of the end-user commands for using fzf on everything: `:Files`,
  " `:Buffers`, `:Helptags`, `:Commands` and so on.
  Plug 'https://github.com/junegunn/fzf.vim', { 'requires': 'fzf' }
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

  " I like these three much better than Vim's and Nvim's default ones:
  Plug 'https://github.com/tbastos/vim-lua'
  Plug 'https://github.com/plasticboy/vim-markdown'
  " (this one highlights function invocations which the default one does not do)
  Plug 'https://github.com/bfrg/vim-cpp-modern'

  " JavaScript and TypeScript development:
  Plug 'https://github.com/pangloss/vim-javascript'
  " TypeScript evolves faster than Vim updates are released, so I include this
  " plugin instead of relying on its copy upstreamed into Vim. Great username btw.
  Plug 'https://github.com/HerringtonDarkholme/yats.vim' " , { 'if': !has('nvim-0.4.0') && !has('patch-8.1.1486') }
  " For some reason, `$VIMRUNTIME` includes support only for TSX out of the
  " box, but not for JSX. By default, JSX filetype is just an alias for JS.
  Plug 'https://github.com/MaxMEllon/vim-jsx-pretty'

  " The Rust language pack bundled with Vim has not been outdated for a long
  " time[1], plus this is an official plugin and it's super good.
  " [1]: <https://github.com/vim/vim/pull/13075>
  Plug 'https://github.com/rust-lang/rust.vim'

  " The indenting script here is just so much better than the default one.
  " Discovered this plugin thanks to vim-polyglot.
  Plug 'https://github.com/Vimjas/vim-python-pep8-indent'

  " Sysadmin stuff:
  Plug 'https://github.com/MTDL9/vim-log-highlighting'
  " I actually got so used to this one since it was included with vim-polyglot,
  " while the `$VIMRUNTIME` just uses plain `dosini` for systemd configs.
  Plug 'https://github.com/wgwoods/vim-systemd-syntax'
  " <https://github.com/vim/vim/commit/6e649224926bbc1df6a4fdfa7a96b4acb1f8bee0>
  " <https://github.com/neovim/neovim/commit/f6a9f0bfcaeb256bac1b1c8273e6c40750664967>
  Plug 'https://github.com/chr4/nginx.vim', { 'if': !has('nvim-0.6.0') && !has('patch-8.2.3474') }

  " Some niche languages that were not included with Vim until recently:
  " <https://github.com/neovim/neovim/commit/79d492a4218ee6b4da5becbebb712a0f1f65d0f5>
  Plug 'https://github.com/tikhomirov/vim-glsl', { 'if': !has('nvim-0.11.0') && !has('patch-9.1.0610') }
  " <https://github.com/neovim/neovim/commit/0ba77f2f31c9de42f1e7a8435e6322d3f0a04fa5>
  Plug 'https://github.com/cespare/vim-toml', { 'if': !has('nvim-0.6.0') && !has('patch-8.2.3520') }
  " <https://github.com/neovim/neovim/commit/3e47e529b0354dbd665202bbc4f485a5160206bf>
  Plug 'https://github.com/cakebaker/scss-syntax.vim', { 'if': !has('nvim-0.5.0') && !has('patch-8.1.2397') }

  " The Lua reference manual[1] and luv documentation[2] are now shipped with Nvim, see:
  " <https://github.com/neovim/neovim/commit/e6680ea7c3912d38f2ef967e053be741624633ad>
  " <https://github.com/neovim/neovim/commit/33ddca6fa0534df2605699070fdd1e5c6e4a7bcf>
  " [1]: <https://www.lua.org/manual/5.1/>
  " [2]: <https://github.com/luvit/luv/blob/master/docs.md>
  if g:vim_ide && has('nvim-0.4.0') && !has('nvim-0.8.0')
    Plug 'https://github.com/bfredl/luarefvim'
    Plug 'https://github.com/nanotee/luv-vimdocs', { 'branch': 'main' }
  endif

  if has('nvim-0.5.0') && !has('nvim-0.7.0')
    " An alternative and optimized filetype detection system. No longer
    " required as it was integrated into the Neovim core in v0.7.0:
    " <https://github.com/neovim/neovim/commit/3fd454bd4a6ceb1989d15cf2d3d5e11d7a253b2d>
    Plug 'https://github.com/nathom/filetype.nvim', { 'branch': 'main' }
  endif
" }}}

" Programming {{{
  if g:vim_ide
    " An interactive Lua playground.
    Plug 'https://github.com/rafcamlet/nvim-luapad', { 'if': has('nvim-0.5.0') }
    " A debugger for Lua scripts running in Neovim itself.
    Plug 'https://github.com/jbyuki/one-small-step-for-vimkind', { 'if': has('nvim-0.7.0') }
    " The built-in LSP client has been introduced in nvim 0.5.0, see
    " <https://github.com/neovim/neovim/commit/a5ac2f45ff84a688a09479f357a9909d5b914294>.
    if has('nvim-0.5.0') && get(g:, 'dotfiles_use_nvimlsp', 0)
      " Collection of pre-made Language Server configs for Neovim's built-in
      " LSP client. Only defines stuff like names of executables of the
      " Servers, default settings and initializationOptions, workspace root
      " dir patterns etc. Might get rid of this soon.
      Plug 'https://github.com/neovim/nvim-lspconfig'
      " The current snippet expansion plugin. Doesn't contain any snippet
      " libraries of its own.
      Plug 'https://github.com/dcampos/nvim-snippy'
      " The current completion plugin.
      Plug 'https://github.com/hrsh7th/nvim-cmp', { 'branch': 'main' }
      " The following plugins are actually completion sources for nvim-cmp:
      " The built-in Language Server client.
      Plug 'https://github.com/hrsh7th/cmp-nvim-lsp', { 'branch': 'main' }
      " Words from buffers (as I like to call them, the "dumb completions").
      Plug 'https://github.com/hrsh7th/cmp-buffer', { 'branch': 'main' }
      " File paths.
      Plug 'https://github.com/hrsh7th/cmp-path', { 'branch': 'main' }
      " Snippets registered in the snippet engine.
      Plug 'https://github.com/dcampos/cmp-snippy'
    else
      Plug 'https://github.com/neoclide/coc.nvim', { 'branch': 'release' }
    endif
    if (has('nvim-0.4.3') || v:version >= 802) && has('python3')
      " A client for the Debug Adapter Protocol.
      Plug 'https://github.com/puremourning/vimspector'
    endif
    " if has('nvim') || v:version >= 801
    "   " Real-time preview of Markdown files in the browser (as the name implies).
    "   Plug 'https://github.com/iamcco/markdown-preview.nvim', { 'do': 'yarn --cwd=app install --frozen-lockfile' }
    " endif
  endif
" }}}
