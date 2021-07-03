let g:nvim_dotfiles_dir = expand('<sfile>:p:h')
let g:dotfiles_dir = expand('<sfile>:p:h:h')

let g:vim_ide = get(g:, 'vim_ide', 0)
let g:vim_ide_treesitter = get(g:, 'vim_ide_treesitter', 0)

let &runtimepath = g:nvim_dotfiles_dir.','.&runtimepath.','.g:nvim_dotfiles_dir.'/after'

" Indent detection hack, stage 1 {{{
" HACK: Set `shiftwidth` to something unreasonable to make Polyglot's built-in
" indentation detector believe that it's the "default" value. The problem
" comes from the fact that Polyglot bundles vim-sleuth, but executes it in an
" autoload script, which is loaded by an ftdetect script, which is... loaded
" when vim-plug invokes `filetype on`. Thus vim-sleuth is loaded way before
" the primary chunk of my configuration is loaded, so it won't see my
" preferred indentation value, save 8 (Vim's default) to a local variable
" `s:default_shiftwidth` and always assume that some ftplugin explicitly
" modified the shiftwidth to 2 (my real default value) for that particular
" filetype. So instead I use a classic approach to rectify the problem:
" ridiculously hacky workarounds. In any case, blame this commit:
" <https://github.com/sheerun/vim-polyglot/commit/113f9b8949643f7e02c29051ad2148c3265b8131>.
let s:fake_default_shiftwidth = 0
let &shiftwidth = s:fake_default_shiftwidth
" }}}

let g:dotfiles_plugin_manager = get(g:, 'dotfiles_plugin_manager', has('nvim-0.5.0') ? 'packer.nvim' : 'vim-plug')

let g:dotfiles_plugins_list_context = {}
let s:ctx = g:dotfiles_plugins_list_context

let s:ctx.implementation = g:dotfiles_plugin_manager
let s:ctx._registered_plugins = []

function! s:ctx._register_plugin(repo, spec) abort
  " How packer.nvim derives plugin names:
  " <https://github.com/wbthomason/packer.nvim/blob/b76bfba54031ad28f17e98ef555e99cf450d6cb3/lua/packer.lua#L169-L176>
  " <https://github.com/wbthomason/packer.nvim/blob/b76bfba54031ad28f17e98ef555e99cf450d6cb3/lua/packer/plugin_utils.lua#L122-L139>
  " How vim-plug derives plugin names:
  " <https://github.com/junegunn/vim-plug/blob/fc2813ef4484c7a5c080021ceaa6d1f70390d920/plug.vim#L715>
  " The algorithms are mostly the same, i.e. getting a basename of the repo
  " slug (with a major difference in that vim-plug uses aliases as-is, and
  " packer.nvim tries to apply the same logic of getting the basename of a path
  " to them as well), but I think I'll go with vim-plug's method.
  if !get(a:spec, 'disable', 0)
    let name = get(a:spec, 'as', fnamemodify(a:repo, ':t:s?\.git$??'))
    call add(self._registered_plugins, name)
  endif
endfunction

if g:dotfiles_plugin_manager == 'packer.nvim'  " {{{

  let s:ctx.repo = 'wbthomason/packer.nvim'
  let s:ctx.plugins_dir = stdpath('data') . '/site/pack/packer'
  let s:ctx.install_path = s:ctx.plugins_dir . '/start/packer.nvim'

  function! s:ctx._auto_install() abort
    if empty(glob(self.install_path))
      execute '!git clone --progress' shellescape('https://github.com/' . self.repo . '.git', 1) shellescape(self.install_path, 1)
    endif
  endfunction

  " HACK: Unfortunately you can't pass a table with mixed integer and string
  " keys as Vim's translation layer complains, so instead we pass the only
  " positional argument (repo) and the rest (spec) separately, and merge them
  " together on the Lua side.
  let s:ctx._use_lua = luaeval(
  \ 'function(repo, spec) require("packer").use(vim.tbl_extend("keep", { repo }, spec)); end')
  function! s:ctx.use(repo, ...) abort
    if a:0 > 1 | throw 'Invalid number of arguments for function (must be 1..2):' . a:0 | endif
    let spec = get(a:000, 0, {})
    call self._use_lua(a:repo, spec)
    call s:ctx._register_plugin(a:repo, spec)
  endfunction

  function! s:ctx._begin() abort
    packadd packer.nvim
    lua << EOF
    local packer = require('packer')
    local ctx = vim.g.dotfiles_plugins_list_context
    packer.init({
      package_root = vim.fn.fnamemodify(ctx.plugins_dir, ':h'),
      plugin_package = vim.fn.fnamemodify(ctx.plugins_dir, ':t'),
    })
    packer.init()
    packer.reset()
EOF
    autocmd User PackerComplete lua require('packer').compile()
    call self.use(self.repo)
  endfunction

  function! s:ctx._end() abort
  endfunction

  function! s:ctx._get_installed_plugins() abort
    " <https://github.com/wbthomason/packer.nvim/blob/30138b6f651a2257c4f0e21d2631fa2d087364f1/lua/packer/plugin_utils.lua#L51-L63>
    let plugins = []
    for subdir in ['opt', 'start']
      " <https://stackoverflow.com/a/13908273/12005228>
      call extend(plugins, map(filter(glob(self.plugins_dir . '/' . subdir . '/{,.}*/', 1, 1), 'isdirectory(v:val)'), 'fnamemodify(v:val, ":h:t")'))
    endfor
    return plugins
  endfunction

  function! s:ctx._sync(need_install, need_clean) abort
    if !empty(a:need_install)
      lua require('packer').install()
    elseif !empty(a:need_clean)
      lua require('packer').clean()
    endif
  endfunction

" }}}
elseif g:dotfiles_plugin_manager == 'vim-plug'  " {{{

  let s:ctx.repo = 'junegunn/vim-plug'
  let s:ctx.install_path = stdpath('config') . '/autoload/plug.vim'
  let s:ctx.plugins_dir = stdpath('data') . '/plugged'

  function! s:ctx._auto_install() abort
    if !filereadable(self.install_path)
      execute '!curl -fL' shellescape('https://raw.githubusercontent.com/' . self.repo . '/master/plug.vim', 1) '--create-dirs -o' shellescape(self.install_path, 1)
    endif
  endfunction

  function! s:ctx.use(repo, ...) abort
    if a:0 > 1 | throw 'Invalid number of arguments for function (must be 1..2):' . a:0 | endif
    let spec = get(a:000, 0, {})

    " vim-plug doesn't have this.
    if !get(spec, 'disable', 0)
      " Translate the parts of packer.nvim specs that vim-plug understands.
      let spec2 = {}
      for key in ['branch', 'tag', 'commit', 'rtp', 'as']
        if has_key(spec, key) | let spec2[key] = spec[key] | endif
      endfor
      for [key, key2] in items({'run': 'do', 'ft': 'for', 'cmd': 'on'})
        if has_key(spec, key) | let spec2[key2] = spec[key] | endif
      endfor
      call plug#(a:repo, spec2)
    endif

    call s:ctx._register_plugin(a:repo, spec)
  endfunction

  function! s:ctx._begin() abort
    call plug#begin(self.plugins_dir)
    call self.use(self.repo)
  endfunction

  function! s:ctx._end() abort
    call plug#end()
  endfunction

  function! s:ctx._get_installed_plugins() abort
    " <https://stackoverflow.com/a/13908273/12005228>
    return map(filter(glob(self.plugins_dir . '/{,.}*/', 1, 1), 'isdirectory(v:val)'), 'fnamemodify(v:val, ":h:t")')
  endfunction

  function! s:ctx._sync(need_install, need_clean) abort
    if !empty(a:need_install)
      PlugInstall --sync
    elseif !empty(a:need_clean)
      PlugClean
    endif
  endfunction

  " }}}
else
  echoerr "Unknown plugin manager:" g:dotfiles_plugin_manager
endif

call s:ctx._auto_install()
call s:ctx._begin()
runtime! dotfiles/plugins-list.vim
call s:ctx._end()

" Automatically install/clean plugins (because I'm a programmer) {{{
  function! s:ctx._check_sync() abort
    " TODO: Perhaps use the old mtime-comparison approach in addition to the
    " current one?
    " <https://github.com/dmitmel/dotfiles/blob/3e272ffaaf3c386e05817a7f08d16e8cf7c4ee5c/nvim/lib/plugins.vim#L88-L108>
    let need_install = {}
    let need_clean = {}
    for name in self._get_installed_plugins()
      let need_clean[name] = 1
    endfor
    for name in self._registered_plugins
      if has_key(need_clean, name)
        unlet need_clean[name]
      else
        let need_install[name] = 1
      endif
    endfor
    if !empty(need_install) || !empty(need_clean)
      call self._sync(need_install, need_clean)
    endif
  endfunction
  autocmd VimEnter * call s:ctx._check_sync()
" }}}

" NOTE: What the following block does is effectively source the files
" `filetype.vim`, `ftplugin.vim`, `indent.vim`, `syntax/syntax.vim` from
" `$VIMRUNTIME` IN ADDITION TO sourcing the plugin scripts, `plugin/**/*.vim`.
" The last bit is very important because the rest of vimrc runs in a world when
" all plugins have been initialized, and so adjustments to e.g. autocommands
" are possible.
if has('autocmd') && !(exists("g:did_load_filetypes") && exists("g:did_load_ftplugin") && exists("g:did_indent_on"))
  filetype plugin indent on
endif
if has('syntax') && !exists('g:syntax_on')
  syntax enable
endif

if g:vim_ide_treesitter
  runtime! dotfiles/treesitter.vim
endif

" Indent detection hack, stage 2 {{{
if exists(':Sleuth')
  " HACK: Continuation of the indentation detection hack. Here I first destroy
  " Polyglot's vim-sleuth's autocommands, fortunately there is just one, which
  " calls `s:detect_indent()` on `BufEnter`. And also registration into tpope's
  " statusline plugin, which I don't use, therefore I don't care.
  augroup polyglot-sleuth
    autocmd!
    " HACK: Now I install my own autocommand, which first resets the local
    " shiftwidth to the unreasonable value picked above, which vim-sleuth
    " internally compares with its local `s:default_shiftwidth`, sees that both
    " are the same, and proceeds to execute the indent detection algorithm.
    " ALSO Note how I'm not using `BufEnter` as vim-sleuth does because
    " apparently `BufWinEnter` leads to better compatibility with the
    " indentLine plugin and potentially less useless invocations (see the note
    " about window splits in the docs for this event). Oh, one last thing:
    " vim-sleuth forgets to assign the tabstop options, which I have to do as
    " well. But anyway, boom, my work here is done.
    autocmd BufWinEnter *
      \  let &l:shiftwidth = s:fake_default_shiftwidth
      \| Sleuth
      \| let &l:tabstop = &l:shiftwidth
      \| let &l:softtabstop = &l:shiftwidth
  augroup END

  " HACK: In case you are wondering why I'm using Polyglot's bundled vim-sleuth
  " given that it requires those terrible hacks to function normally and respect
  " my configs, and not something like <https://github.com/idbrii/detectindent>
  " (this is a fork I used to use and which checks syntax groups to improve
  " detection quality). ...Well, frankly, even though vim-sleuth's detector uses
  " unreliable (at first glance) regex heuristics, in practice it still works
  " better than detectindent's syntax group querying.
endif
" }}}

colorscheme dotfiles
