" <https://github.com/sheerun/vim-polyglot/issues/792>
if exists('g:did_load_polyglot')
  " This will be remembered across reloads
  let s:has_polyglot = 1
endif
if exists('s:has_polyglot')
  " This boosts the startup speed by avoiding sourcing filetype.vim.
  let g:did_load_filetypes = 1
endif
