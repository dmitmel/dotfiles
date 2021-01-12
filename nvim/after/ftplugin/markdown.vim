source <sfile>:h/text.vim

let s:src_file = expand('%')
let s:out_file = s:src_file.'.html'
let &l:makeprg = 'markdown2htmldoc '.shellescape(s:src_file).' '.shellescape(s:out_file)
for s:arg in get(g:, 'dotfiles_markdown2htmldoc_options', [])
  let &l:makeprg .= ' '.shellescape(s:arg)
endfor

nnoremap <buffer> <F5> <Cmd>Open %.html<CR>
