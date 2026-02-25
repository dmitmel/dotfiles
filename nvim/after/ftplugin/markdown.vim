if get(g:, 'dotfiles_treesitter_highlighting', 0)
  " Treesitter can handle the injected languages in the Markdown code blocks.
  " Disable these autocommands of the `vim-markdown` plugin that are responsible
  " for loading syntaxes for code blocks and highlighting them appropriately:
  " <https://github.com/preservim/vim-markdown/blob/8f6cb3a6ca4e3b6bcda0730145a0b700f3481b51/ftplugin/markdown.vim#L901-L910>
  autocmd! Mkd * <buffer>
endif

source <sfile>:h/text.vim

exe dotfiles#ft#set('&makeprg', 'markdown2htmldoc -- %:S %:S.html')
call dotfiles#ft#set('runfileprg', ':Open %.html')

call dotfiles#ft#set('delimitMate_nesting_quotes', ['`'])

setlocal matchpairs-=<:>
call dotfiles#ft#undo_set('&matchpairs')

call dotfiles#ft#set('surround_'.char2nr('*'), "**\r**")
call dotfiles#ft#set('surround_'.char2nr('~'), "~~\r~~")
