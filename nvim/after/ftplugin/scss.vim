source <sfile>:h/css.vim

let s:src_file = expand('%')
let s:out_file = s:src_file.'.css'
let &l:makeprg = 'sass'
for s:arg in get(g:, 'dotfiles_dart_sass_options', [])
  let &l:makeprg .= ' '.shellescape(s:arg)
endfor
let &l:makeprg .= ' -- '.shellescape(s:src_file).':'.shellescape(s:out_file)
