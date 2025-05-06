" HACK: This jank is required to patch the function pencil#init

execute 'source' dotplug#plugin_dir('vim-pencil').'/autoload/pencil.vim'

let s:real_init = funcref('pencil#init')
function! pencil#init(...)  " not abort
  let result = call(s:real_init, a:000)

  " <https://github.com/preservim/vim-pencil/blob/6d70438a8886eaf933c38a7a43a61adb0a7815ed/autoload/pencil.vim#L426-L428>
  silent! iunmap <buffer> <Up>
  silent! iunmap <buffer> <Down>

  return result
endfunction
