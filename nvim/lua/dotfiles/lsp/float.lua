--- Floating preview window patches. Perhaps a re-implementation of
--- <https://github.com/neoclide/coc.nvim/blob/5aa3197360a76200e8beb30c9957fac1205b7ad5/autoload/coc/float.vim>
--- in the future (TODO).
local M = require('dotfiles.autoload')('dotfiles.lsp.float')

local lsp = require('vim.lsp')
local lsp_global_settings = require('dotfiles.lsp.global_settings')
local utils_vim = require('dotfiles.utils.vim')
local utils = require('dotfiles.utils')

-- Backport of <https://github.com/neovim/neovim/pull/16557>.
if not utils_vim.has('nvim-0.6.1') then
  function lsp.util.close_preview_autocmd(close_events, float_winid)
    local float_bufnr = vim.api.nvim_win_get_buf(float_winid)
    local orig_bufnr = vim.api.nvim_get_current_buf()

    local augroup = 'preview_window_' .. float_winid
    vim.cmd('augroup ' .. augroup)
    vim.cmd('autocmd!')
    vim.cmd(
      string.format(
        'autocmd BufEnter * lua vim.lsp.util._close_preview_window(%d, {%d, %d})',
        float_winid,
        float_bufnr,
        orig_bufnr
      )
    )
    if #close_events > 0 then
      vim.cmd(
        string.format(
          'autocmd %s <buffer> lua vim.lsp.util._close_preview_window(%d, {})',
          table.concat(close_events, ','),
          float_winid
        )
      )
    end
    vim.cmd('augroup END')
  end

  function lsp.util._close_preview_window(float_winid, bufnrs)
    vim.schedule(function()
      if vim.tbl_contains(bufnrs or {}, vim.api.nvim_get_current_buf()) then
        return
      end
      if vim.api.nvim_win_is_valid(float_winid) then
        local augroup = 'preview_window_' .. float_winid
        vim.cmd('autocmd! ' .. augroup)
        vim.cmd('augroup! ' .. augroup)
        vim.api.nvim_win_close(float_winid, true)
      end
    end)
  end
end

-- <https://github.com/neovim/neovim/pull/16465>
local HAS_OPEN_FLOAT_OPTION_FOCUS = utils_vim.has('nvim-0.6.0')

--- These variables (Plural because there are two: buf-local and win-local,
--- with the same name. I am very original, I know.) are used to check if the
--- floating window returned by `open_floating_preview` was just created or
--- that function decided to reuse an existing one.
M.BUF_AND_WIN_INIT_CHECK_VAR = 'dotfiles_lsp_float_initialized'

local orig_util_open_floating_preview = lsp.util.open_floating_preview
-- TODO: Re-implement to fix flicker on repeated opens. It is most likely
-- caused by syntax loading between closing of the previous window and opening
-- a new one.
function lsp.util.open_floating_preview(contents, syntax, opts, ...)
  opts = opts or {}
  opts.border = opts.border or lsp_global_settings.DEFAULT_FLOAT_BORDER_STYLE
  opts.close_events = opts.close_events
    or {
      'CursorMoved',
      'CursorMovedI',
      'InsertCharPre',
      -- 'WinScrolled'
    }
  if HAS_OPEN_FLOAT_OPTION_FOCUS then
    opts.focus = utils.if_nil(opts.focus, false)
  else
    opts.focus_id = nil
  end
  local float_bufnr, float_winid = orig_util_open_floating_preview(contents, syntax, opts, ...)

  if not utils.npcall(vim.api.nvim_buf_get_var, float_bufnr, M.BUF_AND_WIN_INIT_CHECK_VAR) then
    vim.api.nvim_buf_set_var(float_bufnr, M.BUF_AND_WIN_INIT_CHECK_VAR, true)
    -- <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/util.lua#L1431>
    vim.api.nvim_buf_set_keymap(float_bufnr, 'n', '<Esc>', '<Cmd>bdelete<CR>', {
      silent = true,
      noremap = true,
    })
  end

  if not utils.npcall(vim.api.nvim_win_get_var, float_winid, M.BUF_AND_WIN_INIT_CHECK_VAR) then
    vim.api.nvim_win_set_var(float_winid, M.BUF_AND_WIN_INIT_CHECK_VAR, true)
    -- <https://github.com/neoclide/coc.nvim/blob/3de26740c2d893191564dac4785002e3ebe01c3a/autoload/coc/float.vim#L166>
    local opt_wrap = vim.api.nvim_win_get_option(float_winid, 'wrap')
    vim.api.nvim_win_set_option(float_winid, 'linebreak', opt_wrap)
  end

  return float_bufnr, float_winid
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
