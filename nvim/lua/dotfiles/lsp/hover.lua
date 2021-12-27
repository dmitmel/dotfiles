--- See also:
--- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#textDocument_hover>
--- <https://github.com/neoclide/coc.nvim/blob/master/autoload/coc/float.vim#L470-L514>
local M = require('dotfiles.autoload')('dotfiles.lsp.hover')

local lsp = require('vim.lsp')
local highlight_match = require('dotfiles.lsp.highlight_match')
local lsp_utils = require('dotfiles.lsp.utils')
local vim_highlight = require('vim.highlight')
local lsp_global_settings = require('dotfiles.lsp.global_settings')
local lsp_markup = require('dotfiles.lsp.markup')
local utils = require('dotfiles.utils')
local lsp_progress = require('dotfiles.lsp.progress')

-- The disabled implementation using builtin APIs has a FATAL FLAW which is
-- described in the `highlight_match` module.
local USE_NVIM_ADD_BUF_HIGHLIGHT = false

M.nvim_namespace = vim.api.nvim_create_namespace(M.__module.name)
M.highlight_last_bufnr = nil
M.highlight_match_ids = {}
M.highlight_timer_stop = nil

-- Based on <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/buf.lua#L57-L62>.
function M.request()
  local params = lsp.util.make_position_params()
  params.workDoneToken = lsp_progress.random_token()
  lsp.buf_request(0, 'textDocument/hover', params)
end
lsp.buf.hover = M.request

-- Based on <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/handlers.lua#L250-L277>.
function M.handler(err, params, ctx, opts)
  if err then
    lsp_utils.client_notify(ctx.client_id, err, vim.log.levels.ERROR)
    return
  end
  opts = opts or {}
  opts.max_width = lsp_global_settings.HOVER_WINDOW_MAX_WIDTH
  opts.max_height = lsp_global_settings.HOVER_WINDOW_MAX_HEIGHT
  opts.focus_id = ctx.method
  if params and params.contents then
    M.highlight_handler(err, params, ctx, opts)
    local renderer = lsp_markup.Renderer:new()
    renderer:parse_documentation_sections(params.contents)
    if not renderer:are_all_lines_empty() then
      renderer:open_in_floating_window(opts)
    end
    -- Note that no error message shouldn't be displayed even when we received
    -- no documentation sections because the `highlight_handler` can be fired
    -- in any case.
    return
  end
  lsp_utils.client_notify(ctx.client_id, 'hover not available', vim.log.levels.WARN)
end
lsp.handlers['textDocument/hover'] = lsp_utils.wrap_handler_compat(M.handler)

-- See:
-- <https://github.com/neoclide/coc.nvim/blob/705135211e84725766e434f59e63ae3592c609d9/src/handler/hover.ts#L74-L79>
-- <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/highlight.lua#L42-L91>
function M.highlight_handler(err, params, ctx, opts)
  if err then
    lsp_utils.client_notify(ctx.client_id, err, vim.log.levels.ERROR)
    return
  end
  local hl_timeout = opts.dotfiles_hl_timeout or 1000
  local higroup = opts.dotfiles_highlight_group or 'LspHover'
  local priority = opts.dotfiles_highlight_priority or 99
  local buf_winids = opts.dotfiles_filter_window_ids or vim.fn.win_findbuf(ctx.bufnr)

  M.clear_highlights()
  if M.highlight_timer_stop then
    M.highlight_timer_stop()
    M.highlight_timer_stop = nil
  end

  if not (params and params.range) then
    return
  end

  M.highlight_last_bufnr = ctx.bufnr
  if USE_NVIM_ADD_BUF_HIGHLIGHT then
    local start_pos, end_pos = params.range['start'], params.range['end']
    vim_highlight.range(
      ctx.bufnr,
      M.nvim_namespace,
      higroup,
      { lsp_utils.position_to_linenr_colnr(ctx.bufnr, start_pos) },
      { lsp_utils.position_to_linenr_colnr(ctx.bufnr, end_pos) }
    )
  else
    for _, winid in ipairs(buf_winids) do
      M.highlight_match_ids[winid] = highlight_match.add_ranges(winid, {
        {
          params.range['start']['line'],
          params.range['start']['character'],
          params.range['end']['line'],
          params.range['end']['character'],
        },
      }, higroup, priority, 'utf-16')
    end
  end

  M.highlight_timer_stop = utils.set_timeout(hl_timeout, function()
    M.highlight_timer_stop = nil
    M.clear_highlights()
  end)
end

function M.clear_highlights()
  if USE_NVIM_ADD_BUF_HIGHLIGHT then
    if M.highlight_last_bufnr then
      vim.api.nvim_buf_clear_namespace(M.highlight_last_bufnr, M.nvim_namespace, 0, -1)
    end
  else
    for winid, match_ids in pairs(M.highlight_match_ids) do
      if vim.api.nvim_win_is_valid(winid) then
        highlight_match.clear_by_ids(winid, match_ids)
      end
    end
    M.highlight_match_ids = {}
  end
end

vim.cmd([[
  augroup dotfiles_lsp_hover
    autocmd!
    autocmd CursorMoved,CursorMovedI,TextChanged,TextChangedI,TextChangedP * unsilent lua require('dotfiles.lsp.hover').clear_highlights()
  augroup END
]])

return M
