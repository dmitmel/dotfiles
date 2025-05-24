source <sfile>:h/text.vim

exe dotutils#ftplugin_set('&makeprg', 'markdown2htmldoc -- %:S %:S.html')
call dotutils#ftplugin_set('runfileprg', ':Open %.html')

call dotutils#ftplugin_set('delimitMate_nesting_quotes', ['`'])

setlocal matchpairs-=<:>
call dotutils#ftplugin_undo_set('matchpairs')
