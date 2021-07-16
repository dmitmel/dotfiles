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
let s:ctx._registered_plugins = {}
let s:ctx._inhibited_plugins = get(g:, 'dotfiles_plugin_manager_inhibited_plugins', {})

function! s:ctx._derive_name(repo, spec)
  " How packer.nvim derives plugin names:
  " <https://github.com/wbthomason/packer.nvim/blob/b76bfba54031ad28f17e98ef555e99cf450d6cb3/lua/packer.lua#L169-L176>
  " <https://github.com/wbthomason/packer.nvim/blob/b76bfba54031ad28f17e98ef555e99cf450d6cb3/lua/packer/plugin_utils.lua#L122-L139>
  " How vim-plug derives plugin names:
  " <https://github.com/junegunn/vim-plug/blob/fc2813ef4484c7a5c080021ceaa6d1f70390d920/plug.vim#L715>
  " The algorithms are mostly the same, i.e. getting a basename of the repo
  " slug (with a major difference in that vim-plug uses aliases as-is, and
  " packer.nvim tries to apply the same logic of getting the basename of a path
  " to them as well), but I think I'll go with vim-plug's method.
  return get(a:spec, 'as', fnamemodify(a:repo, ':t:s?\.git$??'))
endfunction

function! s:ctx._pre_register(repo, spec) abort
  let name = self._derive_name(a:repo, a:spec)
  return get(self._inhibited_plugins, name, 0)
endfunction

function! s:ctx._register(repo, spec) abort
  if !get(a:spec, 'disable', 0)
    let name = self._derive_name(a:repo, a:spec)
    let self._registered_plugins[name] = 1
  endif
endfunction

function! s:ctx.is_registered(name) abort
  return has_key(self._registered_plugins, a:name)
endfunction

" For the use by my beloved forkers of this repository.
function! s:ctx.inhibit_use(name) abort
  if has_key(self._registered_plugins, a:name)
    throw 'Plugin inhibited too late, it has already been registered'
  endif
  let self._inhibited_plugins[a:name] = 1
endfunction

if g:dotfiles_plugin_manager ==# 'packer.nvim'  " {{{

  let s:ctx.repo_name = 'packer.nvim'
  let s:ctx.repo = 'wbthomason/' . s:ctx.repo_name
  let s:ctx.plugins_dir = stdpath('data') . '/site/pack/packer'
  let s:ctx.install_path = s:ctx.plugins_dir . '/start/' . s:ctx.repo_name

  function! s:ctx._auto_install() abort
    if empty(glob(self.install_path))
      execute '!git clone --progress' shellescape('https://github.com/' . self.repo . '.git', 1) shellescape(self.install_path, 1)
    endif
  endfunction

  lua <<EOF
  -- Hacks, hacks, hacks... Unfortunately the Lua integration does not allow
  -- exchanging data between :lua blocks or getting access to s: variables (or
  -- even <SNR>), so we use a global function.
  vim.g.dotfiles_plugins_list_use = function (repo, spec)
    local ctx = vim.g.dotfiles_plugins_list_context
    local spec2 = {}
    -- COUNTERHACK: This is just... bullshit. Don't use plugin dependencies or
    -- anything that affects load order and generates :packadd statements.
    -- Dependencies under packer.nvim are unintuitive, don't solve or fix
    -- anything, and don't work.
    --[[
    -- HACK: Workaround for <https://github.com/wbthomason/packer.nvim/issues/435>.
    if repo == ctx.repo then
      -- The workaround works in two stages: the 1st stage, seen here, triggers
      -- a weird series of conditions in lua/packer/compile.lua which causes
      -- :packadd commands to be generated for dependents of this plugin. This
      -- applies to really any plugin and not just what I chose here, and works
      -- with either `setup`, `config` or maybe other stuff (see
      -- <https://github.com/wbthomason/packer.nvim/issues/272#issuecomment-811254292>).
      -- In simpler words: in order for dependency A of plugin B to really be
      -- loaded before B itself you need to add a `setup`/`config`/etc setting
      -- to the spec of A. In my case, though, I choose the plugin manager to
      -- be the "Chosen One" and apply this `setup` hack just to it.
      spec2.setup = {''}
    else
      -- The second stage consists of adding a dummy dependency on the Chosen
      -- One. This is important because, first of all, this puts the current
      -- plugin into the `opt` directory and not `start`, which allows us to
      -- override the load order in the first place (as pack loading now is not
      -- done by Vim, but by us and :packadd calls). Secondly, this causes
      -- CrossCode mod load order resolving algorithm (also called "sequencing"
      -- in packer.nvim's sources) to be applied to the current plugin, which
      -- is, in general, done only to plugins which have any dependencies.
      spec2.after = {ctx.repo_name}
    end
    -- And so, in the compiled loader script we end up with a dummy call
    -- `:packadd packer.nvim`, which doesn't do anything because packer.nvim's
    -- pack is required for the editor startup and has been already loaded,
    -- and then all plugins sorted by their dependencies.
    ]]

    -- HACK: Unfortunately you can't pass a table with mixed integer and
    -- string keys as Vim's translation layer complains, so instead we pass
    -- the only positional argument (repo) and the rest (spec) separately,
    -- and merge them together on the Lua side.
    for k, v in pairs(spec) do
      spec2[k] = v
    end
    spec2[1] = repo

    require('packer').use(spec2)
  end
EOF

  function! s:ctx.use(repo, ...) abort
    if a:0 > 1 | throw 'Invalid number of arguments for function (must be 1..2):' . a:0 | endif
    let spec = get(a:000, 0, {})
    if s:ctx._pre_register(a:repo, spec) | return | endif
    call g:dotfiles_plugins_list_use(a:repo, spec)
    call s:ctx._register(a:repo, spec)
  endfunction

  function! s:ctx._begin() abort
    execute 'packadd' s:ctx.repo_name
    lua << EOF
    local packer = require('packer')
    local ctx = vim.g.dotfiles_plugins_list_context
    packer.init({
      package_root = vim.fn.fnamemodify(ctx.plugins_dir, ':h'),
      plugin_package = vim.fn.fnamemodify(ctx.plugins_dir, ':t'),
      -- It is actually important that we change the extension of the compiled
      -- loader file to `.vim` because Lua files in `plugin/` are sourced
      -- AFTER all Vimscript files have been sourced.
      compile_path = vim.fn.stdpath('config') .. '/plugin/packer_compiled.vim',
      -- Putting the limit on parallel jobs unfreezes the UI and makes it show
      -- up earlier. Note that you shouldn't use the number of logical CPUs
      -- (`#vim.loop.cpu_info()`) or some similar metric for this because
      -- plugin installation is largely I/O-bound (unless cloning big Git
      -- repositories where a lot of deltas need to be resolved, I guess). The
      -- limit itself was taken from vim-plug, obviously:
      -- <https://github.com/junegunn/vim-plug/blob/fc2813ef4484c7a5c080021ceaa6d1f70390d920/plug.vim#L1156-L1157>
      max_jobs = 16,
    })
    packer.reset()
EOF
    autocmd User PackerComplete lua require('packer').compile()
    call self.use(self.repo, { 'as': self.repo_name })
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
elseif g:dotfiles_plugin_manager ==# 'vim-plug'  " {{{

  let s:ctx.repo_name = 'vim-plug'
  let s:ctx.repo = 'junegunn/' . s:ctx.repo_name
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
    if s:ctx._pre_register(a:repo, spec) | return | endif

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

    call s:ctx._register(a:repo, spec)
  endfunction

  function! s:ctx._begin() abort
    call plug#begin(self.plugins_dir)
    call self.use(self.repo, { 'as': self.repo_name })
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
  echoerr 'Unknown plugin manager:' g:dotfiles_plugin_manager
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
    for name in keys(self._registered_plugins)
      if has_key(need_clean, name)
        unlet need_clean[name]
      else
        let need_install[name] = 1
      endif
    endfor

    if !empty(need_install) || !empty(need_clean)
      enew
      only
      call append(0, repeat(['PLEASE, RESTART THE EDITOR ONCE PLUGIN INSTALLATION FINISHES!!!'], 5))
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
if has('autocmd') && !(exists('g:did_load_filetypes') && exists('g:did_load_ftplugin') && exists('g:did_indent_on'))
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
