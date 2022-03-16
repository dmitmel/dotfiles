function! dotfiles#utils#array_remove_element(array, element) abort
  let index = index(a:array, a:element)
  if index >= 0
    call remove(a:array, index)
  endif
endfunction

function! dotfiles#utils#starts_with(str, prefix) abort
  return empty(a:prefix) || a:str[:len(a:prefix)-1] ==# a:prefix
endfunction

function! dotfiles#utils#ends_with(str, suffix) abort
  return a:str[len(a:str)-len(a:suffix):] ==# a:suffix
endfunction

function! dotfiles#utils#undo_ftplugin_hook(cmd) abort
  if exists('b:undo_ftplugin')
    let b:undo_ftplugin .= ' | ' . a:cmd
  else
    let b:undo_ftplugin = a:cmd
  endif
endfunction

function! dotfiles#utils#add_matchup_prefs(prefs) abort
  if !has_key(g:matchup_matchpref, &filetype)
    let g:matchup_matchpref[&filetype] = {}
  endif
  call extend(g:matchup_matchpref[&filetype], a:prefs)
endfunction

function! dotfiles#utils#add_snippets_extra_scopes(scopes) abort
  if !exists('b:dotfiles_snippets_extra_scopes')
    let b:dotfiles_snippets_extra_scopes = []
  endif
  call extend(b:dotfiles_snippets_extra_scopes, a:scopes)
endfunction

function! dotfiles#utils#set_default(dict, key, default) abort
  if !has_key(a:dict, a:key)
    let a:dict[a:key] = a:default
  endif
  return a:dict[a:key]
endfunction

" Essentially, implements
" <https://github.com/neoclide/coc.nvim/blob/3de26740c2d893191564dac4785002e3ebe01c3a/src/workspace.ts#L810-L844>.
" Alternatively, nvim's implementation can be used:
" <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/util.lua#L966-L991>.
function! dotfiles#utils#jump_to_file(path) abort
  let path = fnamemodify(a:path, ':p')
  " NOTE 1: bufname('') returns the short name, but we need a full one.  NOTE
  " 2: When trying to :edit a file when it is already opened in the current
  " buffer, Vim will attempt to write it and reload the buffer. Honestly, I was
  " surprised to know that this wasn't the case when switching to another
  " buffer, even though another buffer is modified, but it's fine, since :edit
  " handles a ton of edge-cases for us, for instance, opening a previously
  " unlisted buffer.
  if getbufinfo('')[0].name != path
    silent! normal! m'
    execute 'edit' fnameescape(path)
  endif
endfunction

function! dotfiles#utils#open_scratch_preview_win(opts) abort
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

" Opens file or URL with a system program.
function! dotfiles#utils#open_url(path) abort
  " HACK: The 2nd parameter of this function is called 'remote', it tells
  " whether to open a remote (1) or local (0) file. However, it doesn't work as
  " expected in this context, because it uses the 'gf' command if it's opening
  " a local file (because this function was designed to be called from the 'gx'
  " command). BUT, because this function only compares the value of the
  " 'remote' parameter to 1, I can pass any other value, which will tell it to
  " open a local file and ALSO this will ignore an if-statement which contains
  " the 'gf' command.
  return netrw#BrowseX(a:path, 2)
endfunction

function! dotfiles#utils#push_qf_list(opts) abort
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
function! dotfiles#utils#readjust_qf_list_height() abort
  let max_height = get(g:, 'qf_max_height', 10) < 1 ? 10 : get(g:, 'qf_max_height', 10)
  if get(b:, 'qf_isLoc', 0)
    execute 'lclose|' . (get(g:, 'qf_auto_resize', 1) ? min([max_height, len(getloclist(0))]) : '') . 'lwindow'
  else
    execute 'cclose|' . (get(g:, 'qf_auto_resize', 1) ? min([max_height, len(getqflist())]) : '') . 'cwindow'
  endif
endfunction

if has('*nvim_list_runtime_paths')
  function! dotfiles#utils#list_runtime_paths() abort
    return nvim_list_runtime_paths()
  endfunction
else
  function! dotfiles#utils#list_runtime_paths() abort
    return split(&runtimepath, ',')
  endfunction
endif

" Escapes a regular expression and wraps it into slashes, for use in Ex
" commands which take a `{pattern}`.
function! dotfiles#utils#escape_and_wrap_regex(pat) abort
  let pat = a:pat
  let pat = substitute(pat, '\n', '\\n', 'g')
  let pat = substitute(pat, '\r', '\\r', 'g')
  let pat = escape(pat, '/')
  let pat .= pat[-1] ==# '\' ? '\' : ''
  return '/'.pat.'/'
endfunction

function! dotfiles#utils#keepwinview(cmd) abort
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
function! dotfiles#utils#do_confirm() abort
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
function! dotfiles#utils#eunuch_fcall(fn, path, ...) abort
  let fn = get(get(g:, 'io_' . matchstr(a:path, '^\a\a\+\ze:'), {}), a:fn, a:fn)
  return call(fn, [a:path] + a:000)
endfunction
