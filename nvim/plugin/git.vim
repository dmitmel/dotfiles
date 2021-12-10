" Aggressive unlearning of commands:
let g:fugitive_legacy_commands = 0

" De-conflict with completion engines.
let g:gitgutter_sign_priority = 9
let g:signify_priority = g:gitgutter_sign_priority

" Copied from <https://github.com/airblade/vim-gitgutter/blob/42ed714fb9268329f652e053d1de996c77581694/plugin/gitgutter.vim#L48-L59>.
let g:gitgutter_sign_added                   = '+'
let g:gitgutter_sign_modified                = '~'
let g:gitgutter_sign_removed                 = '_'
let g:gitgutter_sign_removed_first_line      = "\u203e"
let g:gitgutter_sign_removed_above_and_below = g:gitgutter_sign_removed . g:gitgutter_sign_removed_first_line
let g:gitgutter_sign_modified_removed        = g:gitgutter_sign_modified . g:gitgutter_sign_removed
" Mirror the look of gitgutter here. TODO: Port this to vim-signify:
" <https://github.com/airblade/vim-gitgutter/blob/24cc47789557827209add5881c226243711475ce/autoload/gitgutter/sign.vim#L209-L218>
let g:signify_sign_show_count = 0
let g:signify_sign_add               = g:gitgutter_sign_added
let g:signify_sign_delete            = g:gitgutter_sign_removed
let g:signify_sign_delete_first_line = g:gitgutter_sign_removed_first_line
let g:signify_sign_change            = g:gitgutter_sign_modified
let g:signify_sign_change_delete     = g:gitgutter_sign_modified_removed

lua <<EOF
  local ok, gitsigns = pcall(require, 'gitsigns')
  vim.g.gitsigns_nvim_available = ok
  if not ok then return end
  gitsigns.setup({
    signs = {
      add          = { text = vim.g.gitgutter_sign_added              };
      delete       = { text = vim.g.gitgutter_sign_removed            };
      topdelete    = { text = vim.g.gitgutter_sign_removed_first_line };
      change       = { text = vim.g.gitgutter_sign_modified           };
      changedelete = { text = vim.g.gitgutter_sign_modified_removed   };
    };
    sign_priority = vim.g.gitgutter_sign_priority;
    preview_config = {
      border = 'none';
      col = 0;
      row = 1;
    };
    -- Disable the default mappings, we will define our own, and via the
    -- intended way.
    keymaps = {};
  })
EOF

" mappings {{{

  nnoremap <leader>gg :<C-u>G
  nnoremap <leader>g  :<C-u>Git<space>
  nnoremap <leader>gs :<C-u>vertical Git<CR>
  nnoremap <leader>gd :<C-u>Gdiffsplit
  nnoremap <leader>gb :<C-u>Git blame<CR>
  nnoremap <leader>gw :<C-u>GBrowse<CR>
  nnoremap <leader>gW :<C-u>.GBrowse<CR>
  xnoremap <leader>gw :GBrowse<CR>
  nnoremap <leader>ga :<C-u>Git add %<CR>
  nnoremap <leader>gc :<C-u>Git commit %
  nnoremap <leader>gC :<C-u>Git commit --amend
  nnoremap <leader>gl :<C-u>Gclog<CR>
  nnoremap <leader>gp :<C-u>Git push
  nnoremap <leader>gP :<C-u>Git push --force-with-lease

  let g:gitgutter_map_keys = 0

  " Jump to the next/previous change in the diff mode because I replace the
  " built-in mappings with coc.nvim's for jumping through diagnostics.
  " TODO: untangle these keybindings. Use `g` for diagnostics and `c` for diff hunks.
  nnoremap [g [c
  nnoremap ]g ]c

  if g:gitsigns_nvim_available
    nnoremap <silent><expr> [g &diff ? '[c' : "\<Cmd>Gitsigns prev_hunk\<CR>"
    nnoremap <silent><expr> ]g &diff ? ']c' : "\<Cmd>Gitsigns next_hunk\<CR>"
    onoremap <silent>       ih :<C-u>Gitsigns select_hunk<CR>
    xnoremap <silent>       ih :<C-u>Gitsigns select_hunk<CR>
  endif

" }}}

" Fugitive.vim handlers {{{

  if !exists('g:fugitive_browse_handlers')
    let g:fugitive_browse_handlers = []
  endif

  if index(g:fugitive_browse_handlers, function('dotfiles#fugitive#aur#handler')) < 0
    call insert(g:fugitive_browse_handlers, function('dotfiles#fugitive#aur#handler'))
  endif

" }}}
