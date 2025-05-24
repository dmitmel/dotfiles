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

function! dotutils#ftplugin_set(name, value) abort
  call dotutils#ftplugin_undo_set(a:name)
  if a:name =~# '^&[a-z]\+$'
    " The caller has to `:execute` this line, so that `verbose set {option}?`
    " displays an appropriate location.
    return 'let &l:' . a:name[1:] . ' = ' . json_encode(a:value)
  else
    " This validates the correctness of variable names for us.
    let b:{a:name} = a:value
    return ''
  endif
endfunction

function! dotutils#ftplugin_undo_set(name) abort
  let b:undo_ftplugin =
  \ (exists('b:undo_ftplugin') ? (b:undo_ftplugin . " | ") : '') .
  \ (a:name =~# '^&[a-z]\+$' ? ('setlocal ' . a:name[1:] . '<') : ('unlet! b:' . a:name))
endfunction

" Essentially, implements
" <https://github.com/neoclide/coc.nvim/blob/3de26740c2d893191564dac4785002e3ebe01c3a/src/workspace.ts#L810-L844>.
" Alternatively, nvim's implementation can be used:
" <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/util.lua#L966-L991>.
function! dotutils#jump_to_file(path) abort
  let path = fnamemodify(a:path, ':p')
  " NOTE 1: bufname('') returns the short name, but we need a full one.
  " NOTE 2: When trying to :edit a file when it is already opened in the
  " current buffer, Vim will attempt to write it and reload the buffer.
  " Honestly, I was surprised to know that this wasn't the case when switching
  " to another buffer, even though another buffer is modified, but it's fine,
  " since :edit handles a ton of edge-cases for us, for instance, opening a
  " previously unlisted buffer.
  if getbufinfo('')[0].name != path
    silent! normal! m'
    edit `=path`
  endif
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

let g:dotutils#use_lua_for_open_uri = get(g:, 'dotutils#use_lua_for_open_uri', 0)

" Opens the URI with a system viewer program.
function! dotutils#open_uri(uri, ...) abort
  if a:0 > 1 | throw "Too many arguments" | endif
  if empty(a:uri) | throw "The uri must not be empty" | endif
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
    call luaeval('vim.ui.open(_A):wait()', a:uri)
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
      " <https://github.com/neovim/neovim/blob/44f1dbee0da3c516541434774b44f74a627b8e3f/runtime/pack/dist/opt/netrw/autoload/netrw.vim#L5148-L5149>
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

function! dotutils#url_under_cursor() abort
  if has('nvim-0.10.0')
    " The Lua URL finder is better than Netrw's default one. It relies on
    " Treesitter though. The `vim.treesitter.highlighter` API was added in Nvim
    " 0.9, but we already checked for version 0.10.
    if luaeval('vim.treesitter.highlighter and vim.treesitter.highlighter.active[_A] ~= nil', bufnr())
      " <https://github.com/neovim/neovim/commit/9762c5e3406cab8152d8dd161c0178965d841676>
      let url = luaeval('vim.ui._get_urls and vim.ui._get_urls()[1]')
      if !empty(url) | return url | endif
      " <https://github.com/neovim/neovim/commit/f864b68c5b0fe1482249167712cd16ff2b50ec45>
      let url = luaeval('vim.ui._get_url and vim.ui._get_url()')
      if !empty(url) | return url | endif
    endif
  endif
  try
    " Actually, some code was added to the Netrw code to add your own helpers
    " for getting the URL, particularly in markdown:
    " <https://github.com/vim/vim/commit/3d7e567ea7392e43a90a6ffb3cd49b71a7b59d1a>.
    return netrw#GX()
  catch /^Vim\%((\a\+)\)\=:E117:.*\<netrw#GX\>/
    " This function was finally removed in Netrw v176
    " <https://github.com/vim/vim/commit/ec961b05dcc1efb0a234f6d0b31a0945517e75d2>.
    " As a last effort let's rely on a copy of code from the latest Vim 9
    " <https://github.com/vim/vim/blob/23984602327600b7ef28dcedc772949d5c66b57f/runtime/plugin/openPlugin.vim#L24>
    return matchstr(expand("<cWORD>"), '\%(\%(http\|ftp\|irc\)s\?\|file\)://\S\{-}\ze[^A-Za-z0-9/]*$')
  endtry
endfunction

function! dotutils#reveal_file(path) abort
  if empty(a:path) | throw "The path must not be empty" | endif
  let path = fnamemodify(a:path, ':p')
  if has('macunix')
    call system('open -R ' . shellescape(path, 0))
  elseif has('unix') && executable('dbus-send')
    " <http://www.freedesktop.org/wiki/Specifications/file-manager-interface/>
    let cmd = 'dbus-send --print-reply --reply-timeout=1000 --dest=org.freedesktop.FileManager1'
    let cmd .= ' /org/freedesktop/FileManager1 org.freedesktop.FileManager1.ShowItems'
    let url = 'file://' . dotutils#url_encode(path, '/')
    let cmd .= ' array:string:' . shellescape(url, 0) . " string:''"
    let output = system(cmd)
    if v:shell_error
      echoerr output
    endif
  else
    " for other systems let's just open the file's parent directory
    call dotutils#open_uri(fnamemodify(path, ':h'))
  endif
endfunction

function! dotutils#push_qf_list(opts) abort
  let loclist_window = get(a:opts, 'dotfiles_loclist_window', 0)
  let action = get(a:opts, 'dotfiles_action', ' ')
  let auto_open = get(a:opts, 'dotfiles_auto_open', 1)
  if loclist_window
    call setloclist(loclist_window, [], action, a:opts)
    if auto_open | call qf#OpenLoclist() | endif
  else
    call setqflist([], action, a:opts)
    if auto_open | call qf#OpenQuickfix() | endif
  endif
endfunction

" Essentially a part of <https://github.com/romainl/vim-qf/blob/65f115c350934517382ae45198a74232a9069c2a/autoload/qf.vim#L86-L108>.
function! dotutils#readjust_qf_list_height() abort
  let max_height = get(g:, 'qf_max_height', 10) < 1 ? 10 : get(g:, 'qf_max_height', 10)
  if get(b:, 'qf_isLoc', 0)
    execute 'lclose|' . (get(g:, 'qf_auto_resize', 1) ? min([max_height, len(getloclist(0))]) : '') . 'lwindow'
  else
    execute 'cclose|' . (get(g:, 'qf_auto_resize', 1) ? min([max_height, len(getqflist())]) : '') . 'cwindow'
  endif
endfunction

if has('*nvim_list_runtime_paths')
  function! dotutils#list_runtime_paths() abort
    return nvim_list_runtime_paths()
  endfunction
else
  function! dotutils#list_runtime_paths() abort
    return split(&runtimepath, ',')
  endfunction
endif

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

function! dotutils#keepwinview(cmd) abort
  let view = winsaveview()
  try
    execute a:cmd
  finally
    call winrestview(view)
  endtry
endfunction

" non-0 = can proceed
" 0     = action cancelled
" 1     = file written, safe to proceed
" 2     = ignore unsaved changes, proceed forcibly
function! dotutils#do_confirm() abort
  if &confirm && &modified
    let fname = expand('%')
    if empty(fname)
      " <https://github.com/neovim/neovim/blob/47f99d66440ae8be26b34531989ac61edc1ad9fe/src/nvim/ex_docmd.c#L9327-L9337>
      let fname = 'Untitled'
    endif
    " <https://github.com/neovim/neovim/blob/a282a177d3320db25fa8f854cbcdbe0bc6abde7f/src/nvim/ex_cmds2.c#L1400>
    let answer = confirm("Save changes to \"".fname."\"?", "&Yes\n&No\n&Cancel")
    if answer ==# 1      " Yes
      write
      return 1
    elseif answer ==# 2  " No
      return 2
    else                 " Cancel/Other
      return 0
    endif
  else
    return 1
  endif
endfunction

" Copied from <https://github.com/tpope/vim-eunuch/blob/7fb5aef524808d6ba67d6d986d15a2e291194edf/plugin/eunuch.vim#L26-L32>.
function! dotutils#eunuch_fcall(fn, path, ...) abort
  let fn = get(get(g:, 'io_' . matchstr(a:path, '^\a\a\+\ze:'), {}), a:fn, a:fn)
  return call(fn, [a:path] + a:000)
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
  let number_str = substitute(number_str, '\v(\.0*)=$', '', '')
  return number_str . unit
endfunction
