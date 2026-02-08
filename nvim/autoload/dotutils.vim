function! dotutils#starts_with(str, prefix) abort
  return empty(a:prefix) || a:str[:len(a:prefix)-1] ==# a:prefix
endfunction

function! dotutils#ends_with(str, suffix) abort
  return a:str[len(a:str)-len(a:suffix):] ==# a:suffix
endfunction

function! dotutils#add_unique(list, element) abort
  if index(a:list, a:element) < 0
    call add(a:list, a:element)
  endif
endfunction

" Taken from <https://vim.fandom.com/wiki/Replace_a_builtin_command_using_cabbrev>
function! dotutils#cmd_alias(lhs, rhs) abort
  return printf("cabbrev %s <C-r>=(getcmdpos()==1 && getcmdtype()==':' ? %s : %s)<CR>",
  \             a:lhs, string(a:rhs), string(a:lhs))
endfunction

function! dotutils#open_scratch_preview_win(opts) abort
  let result = {}

  " Actual implementation of :pedit
  " <https://github.com/neovim/neovim/blob/v0.5.0/src/nvim/ex_cmds.c#L4585-L4624>
  " <https://github.com/neovim/neovim/blob/v0.5.0/src/nvim/ex_docmd.c#L8596-L8617>

  " I hope that the wisdom of Python optimization applies and that implied
  " loops (i.e. filter and map) are faster than real loops. Also, I don't
  " remember get() working on arrays! Oh, wait, that was in Python again...
  let pwin_info = get(filter(getwininfo(), "gettabwinvar(v:val.tabnr, v:val.winnr, '&previewwindow')"), 0)

  let open_cmd = ['noswapfile']
  call extend(open_cmd, get(a:opts, 'create_modifiers', []))

  let setup_cmds = ['setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nomodeline']
  " These were copied from the C code:
  call add(setup_cmds, 'setlocal previewwindow winfixheight foldcolumn=0')
  call extend(setup_cmds, get(a:opts, 'setup_commands', []))
  " Why is there no Vimscript function to do this???
  call add(setup_cmds, 'silent file ' . fnameescape('preview://' . get(a:opts, 'title', '[Scratch]')))

  " :pedit is not used here directly because it has troubles splitting
  " vertically. Plus, a nice side-effect of using :new (and its variations) is
  " that we won't ever accidentally open an existing file.
  if empty(pwin_info)
    call add(open_cmd, get(a:opts, 'vertical', 0) ? 'vnew' : &previewheight . 'new')
    call add(open_cmd, '+' . fnameescape(join(setup_cmds, ' | ')))
    execute join(open_cmd, ' ')
  else
    call win_gotoid(pwin_info.winid)
    call add(open_cmd, 'enew')
    execute join(open_cmd, ' ')
    " Yeah, :enew can't handle the +cmd operand, unlike its relatives...
    execute join(setup_cmds, ' | ')
  endif

  let result.winid = win_getid()
  let [result.tabnr, result.winnr] = win_id2tabwin(result.winid)
  let result.bufnr = winbufnr(result.winid)

  " Switching back and forth causes Airline to consistently redraw. Otherwise
  " it won't detect that the window has &previewwindow set.
  wincmd w
  if get(a:opts, 'switch', 1)
    call win_gotoid(result.winid)
  endif

  if has_key(a:opts, 'text_lines')
    call setbufline(result.bufnr, 1, a:opts.text_lines)
  elseif has_key(a:opts, 'text')
    call setbufline(result.bufnr, 1, split(a:opts.text, "\n"))
  endif

  return result
endfunction

let g:dotutils#use_lua_for_open_uri = get(g:, 'dotutils#use_lua_for_open_uri', has('nvim-0.12.0'))

" Opens the URI with a system viewer program.
function! dotutils#open_uri(uri, ...) abort
  if a:0 > 1 | throw 'Too many arguments' | endif
  if empty(a:uri) | throw 'The uri must not be empty' | endif
  let opts = get(a:000, 0, {})
  " So, for the longest time I've been using Netrw's internal function
  " `netrw#BrowseX` for opening URLs in the browser, but as of Nvim 0.10 and
  " Vim 9 the editors began adding public APIs to the standard library for this
  " exact purpose. There is a bumpy transitional period between Nvim 0.10 and
  " Nvim 0.11, when Nvim had both Lua and Netrw implementation of the URL
  " opener --- the logic in this function exists to untangle that mess.
  if has('nvim-0.10.0') && g:dotutils#use_lua_for_open_uri
    " `vim.ui.open` was added in Nvim 0.10.0
    " <https://github.com/neovim/neovim/commit/af6e6ccf3dee815850639ec5613dda3442caa7d6>,
    " but did not replace Netrw mechanism until Nvim 0.11.0
    " <https://github.com/neovim/neovim/commit/4913b7895cdd3fffdf1521ffb0c13cdeb7c1d27e>.
    " The implementation of `vim.ui.open` received more improvements over time,
    " but still, as of Nvim 0.11.0, it does not support nearly all environments
    " that the Netrw code does, so for now I prefer not to rely on it.
    call luaeval('vim.ui.open(_A):wait(3000)', a:uri)
  elseif has('vim9script') && !has('nvim') && has('patch-9.1.1054')
    " Vim 9 has simply decoupled the `Open` function from Netrw at some point
    " <https://github.com/vim/vim/commit/c729d6d154e097b439ff264b9736604824f4a5f4>
    " into a proper public API, implemented in vim9script. Newest Vim versions
    " have now gotten rid of the function `netrw#Open` and replaced it with
    " `dist#vim9#Open`: <https://github.com/vim/vim/commit/839fd942654b2a7c90ad0633b1c8bb9da4094cbb>.
    call dist#vim9#Open(a:uri)
  else
    try
      " An `:Open` command was added to Vim in Netrw v174 (since Vim v9.1.0819)
      " <https://github.com/vim/vim/commit/3d7e567ea7392e43a90a6ffb3cd49b71a7b59d1a>,
      " and its functionality was exposed as a function a dozen commits later
      " <https://github.com/vim/vim/commit/8b0fa7a565d8aec306e5755307d182fa7d81e65f>.
      " These have also been backported to Neovim 0.11.0:
      " <https://github.com/neovim/neovim/commit/c1e020b7f3457d3a14e7dda72a4f6ebf06e8f91d>,
      " <https://github.com/neovim/neovim/commit/4913b7895cdd3fffdf1521ffb0c13cdeb7c1d27e>.
      " For now, while Nvim ships with both `vim.ui.open` and `netrw#Open`, I'm
      " going to rely on the later. Also, interesting fact, the current usage
      " of this function in the netrw bundled with Nvim 0.11.0 is incorrect:
      " <https://github.com/neovim/neovim/blob/v0.11.0/runtime/pack/dist/opt/netrw/autoload/netrw.vim#L5148-L5149>
      " `escape()` is unnecessary here. It has since been removed:
      " <https://github.com/vim/vim/commit/2328a39a54fbd75576769193d7ff1ed2769e2ff9>.
      call netrw#Open(a:uri)
    catch /^Vim\%((\a\+)\)\=:E117:.*\<netrw#Open\>/
      " If all else fails, we fall back to my good old
      " HACK: Just re-use the `netrw#BrowseX` function that powers the `gx` mapping.
      " There is one catch though: the `gx` mapping is supposed to work in
      " Netrw file manager buffers as well, and if I understand the code
      " correctly, when browsing a remote DIRECTORY it will cause the remote
      " files to be downloaded and opened in the editor, which is not what I
      " want. I want `gx` to ALWAYS open the URL with the system viewer. To
      " change that I abuse the 2nd parameter of this function. It is called
      " `remote`, it tells whether the file in the current buffer is remote (1)
      " or local (0). BUT, the code in the function only compares the value of
      " the 'remote' parameter to 1, so I can pass any other non-zero value,
      " which will make it assume the current file is remote, but will
      " short-citcuit the logic designed for downloading remote files.
      call netrw#BrowseX(a:uri, 2)
    endtry
  endif
endfunction

let s:netrw_GX_exists = 1

function! dotutils#url_under_cursor() abort
  if has('nvim-0.10.0')
    " The Lua URL finder is better than Netrw's default one. It relies on
    " Treesitter though. The `vim.treesitter.highlighter` API was added in Nvim
    " 0.9, but we already checked for version 0.10.
    " <https://github.com/neovim/neovim/commit/9762c5e3406cab8152d8dd161c0178965d841676>
    " <https://github.com/neovim/neovim/commit/f864b68c5b0fe1482249167712cd16ff2b50ec45>
    return luaeval('(vim.ui._get_url and { vim.ui._get_url() } or vim.ui._get_urls())[1]')
  endif

  if s:netrw_GX_exists
    try
      " Actually, some code was added to the Netrw code to add your own helpers
      " for getting the URL, particularly in markdown:
      " <https://github.com/vim/vim/commit/3d7e567ea7392e43a90a6ffb3cd49b71a7b59d1a>.
      let url = netrw#GX()
      " Direct `return netrw#GX()` does not work if Vim is too old.
      return url
    catch /^Vim\%((\a\+)\)\=:E117:.*:\s*netrw#GX$/
      " This function was finally removed in Netrw v176.
      " <https://github.com/vim/vim/commit/ec961b05dcc1efb0a234f6d0b31a0945517e75d2>.
      let s:netrw_GX_exists = 0
    endtry
  endif

  " As a last ditch effort let's rely on a snippet from the latest Vim 9.
  " <https://github.com/vim/vim/blob/v9.1.1406/runtime/plugin/openPlugin.vim#L24>
  return matchstr(expand('<cWORD>'), '\%(\%(http\|ftp\|irc\)s\?\|file\)://\S\{-}\ze[^A-Za-z0-9/]*$')
endfunction

function! dotutils#reveal_file(path) abort
  if empty(a:path) | throw 'The path must not be empty' | endif
  let path = fnamemodify(a:path, ':p')
  if has('macunix')
    call system('open -R ' . shellescape(path, 0))
  elseif has('unix') && executable('dbus-send')
    " <http://www.freedesktop.org/wiki/Specifications/file-manager-interface/>
    let output = system([ 'dbus-send',
    \ '--print-reply', '--reply-timeout=1000', '--dest=org.freedesktop.FileManager1',
    \ '/org/freedesktop/FileManager1', 'org.freedesktop.FileManager1.ShowItems',
    \ 'array:string:' . ('file://' . dotutils#url_encode(path,'/')), "string:''" ])
    if v:shell_error
      throw output
    endif
  else
    " for other systems let's just open the file's parent directory
    call dotutils#open_uri(fnamemodify(path, ':h'))
  endif
endfunction

function! dotutils#list_runtime_paths() abort
  return exists('*nvim_list_runtime_paths') ? nvim_list_runtime_paths() : split(&runtimepath, ',')
endfunction

function! dotutils#gettext(str) abort
  return exists('*gettext') ? gettext(a:str) : a:str
endfunction

function! dotutils#format_exception(throwpoint, exception) abort
  return
  \ (empty(a:throwpoint) ? '' :
  \ printf(dotutils#gettext('Error detected while processing %s:'), a:throwpoint) . "\n")
  \ . substitute(a:exception, '^Vim\%((\a\+)\)\=:', '', '')
endfunction

function! dotutils#literal_regex(pat) abort
  let pat = escape(a:pat, '\')
  let pat = substitute(pat, '\n', '\\n', 'g')
  let pat = substitute(pat, '\r', '\\r', 'g')
  return '\V' . pat
endfunction

" Escapes a regular expression and wraps it into slashes, for use in Ex
" commands which take a `{pattern}`.
function! dotutils#escape_and_wrap_regex(pat) abort
  let pat = a:pat
  let pat = substitute(pat, '\n', '\\n', 'g')
  let pat = substitute(pat, '\r', '\\r', 'g')
  let pat = escape(pat, '/')
  let pat .= pat[-1] ==# '\' ? '\' : ''
  return '/'.pat.'/'
endfunction

" Copied from <https://github.com/tpope/vim-unimpaired/blob/master/plugin/unimpaired.vim#L459-L462>
function! dotutils#url_encode(str, allowed_chars) abort
  " iconv trick to convert utf-8 bytes to 8bits indiviual char.
  let bytestr = iconv(a:str, 'latin1', 'utf-8')
  let regex = '[^' . escape(a:allowed_chars, ']\') . 'A-Za-z0-9_.~-]'
  return substitute(bytestr, regex, '\="%".printf("%02X",char2nr(submatch(0)))', 'g')
endfunction

" Copied from <https://github.com/tpope/vim-unimpaired/blob/master/plugin/unimpaired.vim#L464-L467>
function! dotutils#url_decode(str) abort
  let str = substitute(substitute(substitute(a:str, '%0[Aa]\n$', '%0A', ''), '%0[Aa]', '\n', 'g'), '+', ' ', 'g')
  return iconv(substitute(str, '%\(\x\x\)', '\=nr2char("0x".submatch(1))', 'g'), 'utf-8', 'latin1')
endfunction

function! dotutils#file_size_fmt(bytes) abort
  let next_factor = 1
  for unit in ['B', 'K', 'M', 'G', 'T']
    let factor = next_factor
    let next_factor = factor * 1024
    if abs(a:bytes) < next_factor | break | endif
  endfor
  let number_str = printf('%.2f', (a:bytes * 1.0) / factor)
  " remove trailing zeros
  let number_str = substitute(number_str, '\.0\+$', '', '')
  return number_str . unit
endfunction

function! dotutils#is_terminal_running(buf) abort
  if has('nvim')
    let job = getbufvar(a:buf, exists('&channel') ? '&channel' : 'terminal_job_id', 0)
    return jobwait([job], 0)[0] == -1
  elseif has('terminal')
    return term_getstatus(a:buf) =~# '\<running\>'
  else
    return 0
  endif
endfunction

let s:XDG_DIR_TYPES = {
\ 'data':    ['XDG_DATA_HOME',   '.local/share', '$LOCALAPPDATA'     ],
\ 'config':  ['XDG_CONFIG_HOME', '.config',      '$LOCALAPPDATA'     ],
\ 'cache':   ['XDG_CACHE_HOME',  '.cache',       '$LOCALAPPDATA/Temp'],
\ 'state':   ['XDG_STATE_HOME',  '.local/state', '$LOCALAPPDATA'     ],
\ 'bin':     ['XDG_BIN_HOME',    '.local/bin',   ''                  ],
\ 'runtime': ['XDG_RUNTIME_DIR', '',             ''                  ],
\}

" <https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html>
" <https://www.freedesktop.org/wiki/Software/xdg-user-dirs/>
" <https://github.com/neovim/neovim/blob/v0.5.0/src/nvim/os/stdpaths.c>
" <https://github.com/dirs-dev/dirs-sys-rs/blob/v0.3.4/src/lib.rs>
" <https://github.com/dirs-dev/dirs-rs/blob/d1c9b298df17b7d6ad4c5bc1f42b59888113d182/src/lin.rs>
" <https://stackoverflow.com/questions/43853548/xdg-basedir-directories-for-windows>
function! dotutils#xdg_dir(what) abort
  let [unix_env_var, unix_default_path, windows_path] = s:XDG_DIR_TYPES[a:what]
  if has('unix')
    let env_path = getenv(unix_env_var)
    if env_path =~# '^/'
      return env_path
    elseif !empty(unix_default_path)
      return expand('~/'.unix_default_path)
    endif
  elseif has('win32')
    return expand(windows_path)
  endif
  return v:null
endfunction

" Polyfill for |getscriptinfo()|, which was added only relatively recently, in
" patch 9.0.0244. See also |scriptnames-dictionary|.
function! dotutils#list_loaded_scripts() abort
  if exists('*getscriptinfo') | return getscriptinfo() | endif
  let scripts = []
  for line in split(execute('scriptnames'), "\n")
    let groups = matchlist(line, '\v^\s*(\d+):\s*(.*)\s*$')
    if empty(groups) | continue | endif
    call add(scripts, { 'name': fnamemodify(groups[2], ':p'), 'sid': str2nr(groups[1], 10) })
  endfor
  return scripts
endfunction
