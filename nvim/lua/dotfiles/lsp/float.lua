--- Floating preview window patches. Perhaps a re-implementation of
--- <https://github.com/neoclide/coc.nvim/blob/5aa3197360a76200e8beb30c9957fac1205b7ad5/autoload/coc/float.vim>
--- in the future (TODO).
local M = require('dotfiles.autoload')('dotfiles.lsp.float')

local lsp = require('vim.lsp')
local lsp_global_settings = require('dotfiles.lsp.global_settings')


local orig_util_close_preview_autocmd = lsp.util.close_preview_autocmd
-- We patch this function instead of `open_floating_preview` for customizing
-- the preview window. Why? Because `open_floating_preview` may reuse an
-- already open window, these cases must be ignored, but there is no way to
-- tell from its return values if a window has been reused. However,
-- `close_preview_autocmd` is always called only during setup of the window
-- (<https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/util.lua#L1432>),
-- which is an ideal injection point for me.
function lsp.util.close_preview_autocmd(...)
  local _, floating_winid = ...
  local floating_bufnr = vim.api.nvim_win_get_buf(floating_winid)

  -- <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/util.lua#L1431>
  vim.api.nvim_buf_set_keymap(floating_bufnr, 'n', '<Esc>', '<Cmd>bdelete<CR>', {silent = true, noremap = true})
  -- <https://github.com/neoclide/coc.nvim/blob/3de26740c2d893191564dac4785002e3ebe01c3a/autoload/coc/float.vim#L166>
  vim.api.nvim_win_set_option(floating_winid, 'linebreak', vim.api.nvim_win_get_option(floating_winid, 'wrap'))

  return orig_util_close_preview_autocmd(...)
end


local orig_util_open_floating_preview = lsp.util.open_floating_preview
-- ...Although patching the `open_floating_preview` function is still useful,
-- for instance, to set global default options.
-- TODO: Re-implement to fix flicker on repeated opens. It is most likely
-- caused by syntax loading between closing of the previous window and opening
-- a new one.
function lsp.util.open_floating_preview(contents, syntax, opts, ...)
  opts = opts or {}
  opts.border = opts.border or lsp_global_settings.DEFAULT_FLOAT_BORDER_STYLE
  opts.close_events = opts.close_events or {
    'CursorMoved',
    'CursorMovedI',
    'InsertCharPre',
    'BufLeave',
    -- 'WinScrolled'
  }
  opts.focus_id = nil
  return orig_util_open_floating_preview(contents, syntax, opts, ...)
end


local orig_util_make_floating_popup_options = lsp.util.make_floating_popup_options
function lsp.util.make_floating_popup_options(...)
  local opts = orig_util_make_floating_popup_options(...)
  -- THANK GOD THIS OPTION EXISTS!!! Anyway, this is actually a very important
  -- workaround for a bug in Airline which causes huge slowdowns over time (see
  -- <https://github.com/vim-airline/vim-airline/issues/1779>). And it also
  -- prevents some of the flicker when opening preview windows.
  opts.noautocmd = true
  return opts
end


return M