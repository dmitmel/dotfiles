" Based on <https://github.com/vim-airline/vim-airline/blob/70b06be4b067fec44756e843e2445cce5c97082f/autoload/airline/extensions/example.vim>

let s:update_interval = get(g:, 'airline#extensions#filesize#update_interval', 0.5)
let s:start_reltime = reltime()

function! airline#extensions#filesize#init(ext) abort
  call airline#parts#define_function('filesize', 'airline#extensions#filesize#get')
  call a:ext.add_statusline_func('airline#extensions#filesize#apply')
endfunction

function! airline#extensions#filesize#apply(...) abort
  call airline#extensions#append_to_section('y', airline#section#create_right(['', '', 'filesize']))
endfunction

" Finally, this function will be invoked from the statusline.
function! airline#extensions#filesize#get() abort
  " Use several preliminary checks to prevent frequent updates. You see,
  " line2byte() has to iterate the entire file to calculate its byte size.
  " <https://github.com/vim-airline/vim-airline/blob/ecac148e19fe28d0f13af5f99d9500c2eadefe4c/autoload/airline/extensions/wordcount.vim#L78-L82>
  " <https://github.com/vim-airline/vim-airline/blob/2e9df43962539e3a05e5571c63ccf6356451d46c/autoload/airline/extensions/lsp.vim#L95-L100>
  " Implementation of wordcount: <https://github.com/neovim/neovim/blob/v0.5.0/src/nvim/ops.c#L5590-L5830>
  " Implementation of line2byte: <https://github.com/neovim/neovim/blob/v0.5.0/src/nvim/memline.c#L3987-L4129>
  if empty(get(b:, 'dotfiles_filesize_str', '')) ||
      \ (get(b:, 'dotfiles_filesize_changedtick', 0) != b:changedtick &&
      \ reltimefloat(reltime(s:start_reltime)) - get(b:, 'dotfiles_filesize_timer') >= s:update_interval)
    " MUCH faster than wordcount().bytes because it does a lot less work.
    let bytes = max([0, line2byte(line('$') + 1) - 1])
    let b:dotfiles_filesize = bytes
    let b:dotfiles_filesize_str = dotutils#file_size_fmt(bytes)
    let b:dotfiles_filesize_changedtick = b:changedtick
    let b:dotfiles_filesize_timer = reltimefloat(reltime())
  endif

  return b:dotfiles_filesize_str
endfunction
