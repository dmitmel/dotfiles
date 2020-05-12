execute 'source' fnameescape(expand('<sfile>:p:h').'/text.vim')

let s:src_file = expand('%')
let s:out_file = s:src_file.'.html'
let &l:makeprg = 'markdown2htmldoc '.shellescape(s:src_file).' '.shellescape(s:out_file)
