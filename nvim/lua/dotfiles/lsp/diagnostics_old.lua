--- Legacy patches to <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/diagnostic.lua>.
local M = require('dotfiles.autoload')('dotfiles.lsp.diagnostics')

local lsp = require('vim.lsp')
local DiagnosticSeverity = lsp.protocol.DiagnosticSeverity
local DiagnosticTag = lsp.protocol.DiagnosticTag
local lsp_global_settings = require('dotfiles.lsp.global_settings')
local lsp_utils = require('dotfiles.lsp.utils')
local vim_highlight = require('vim.highlight')
local utils = require('dotfiles.utils')


lsp.handlers['textDocument/publishDiagnostics'] = lsp.with(lsp.diagnostic.on_publish_diagnostics, {
  underline = true;
  virtual_text = {
    prefix = '#';
    spacing = 1;
  };
  signs = {
    priority = 10;  -- De-conflict with vim-signify.
  };
  severity_sort = true;
})


-- Copied from <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/diagnostic.lua#L14-L35>
function M.to_severity(severity)
  if not severity then return nil end
  return type(severity) == 'string' and DiagnosticSeverity[severity] or severity
end


-- Copied from <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/diagnostic.lua#L769-L807>
-- See also <https://gist.github.com/tjdevries/ccbe3b79bd918208f2fa8dfe15b95793/735cbfd559471f139de37b66db89c7b95be7f042>
-- See also <https://github.com/neoclide/coc.nvim/blob/705135211e84725766e434f59e63ae3592c609d9/src/diagnostic/buffer.ts#L255-L264>
function lsp.diagnostic.get_virtual_text_chunks_for_line(bufnr, line, line_diags, opts)
  local line_diags_len = #line_diags
  if line_diags_len == 0 then return nil end

  opts = opts or {}
  local prefix = opts.prefix or '#'
  local spacing = opts.spacing or 1

  local get_virtual_text_highlight = lsp.diagnostic._get_severity_highlight_name

  local main_diag = nil
  local max_severity = nil
  for _, diag in ipairs(line_diags) do
    if diag.severity and (not max_severity or diag.severity < max_severity) then
      max_severity = diag.severity
      main_diag = diag
    end
  end

  local virt_texts = {{string.rep(' ', spacing)}}

  -- if line_diags_len > 1 then
  table.insert(virt_texts, {' ', get_virtual_text_highlight(main_diag.severity)})
  for _, diag in ipairs(line_diags) do
    table.insert(virt_texts, {prefix, get_virtual_text_highlight(diag.severity)})
  end
  -- end

  local str = ' '
  if main_diag.message then
    str = str .. main_diag.message:gsub('[\n\r]', ' \\ ') .. ' '
  end
  table.insert(virt_texts, {str, get_virtual_text_highlight(main_diag.severity)})

  return virt_texts
end


function lsp.diagnostic.set_underline(diagnostics, bufnr, client_id, diagnostic_ns, opts)
  opts = opts or {}

  diagnostic_ns = diagnostic_ns or lsp.diagnostic._get_diagnostic_namespace(client_id)
  -- Copied from <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/diagnostic.lua#L28-L35>
  local filter_level = M.to_severity(opts.severity_limit)
  if filter_level then
    diagnostics = vim.tbl_filter(function(d) return d.severity <= filter_level end, diagnostics)
  end

  for _, d in ipairs(diagnostics) do
    -- The changed part (abstracted into a function):
    local higroup = lsp.diagnostic.get_underline_highlight_group(d)
    -- TODO: use dotfiles.highlight_match?
    vim_highlight.range(
      bufnr,
      diagnostic_ns,
      higroup,
      -- <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/diagnostic.lua#L37-L44>
      -- But our variant is even better.
      {lsp_utils.position_to_linenr_colnr(bufnr, d.range['start'])},
      {lsp_utils.position_to_linenr_colnr(bufnr, d.range['end'])}
    )
  end
end


local underline_highlight_map = {}
for _, name in ipairs({'Error', 'Warning', 'Information', 'Hint', 'Unnecessary', 'Deprecated'}) do
  underline_highlight_map[name] = 'LspDiagnosticsUnderline' .. name
end


-- See also: <https://github.com/neoclide/coc.nvim/blob/705135211e84725766e434f59e63ae3592c609d9/src/diagnostic/buffer.ts#L342-L362>
function lsp.diagnostic.get_underline_highlight_group(diagnostic)
  if diagnostic.tags then
    for _, tag in ipairs(diagnostic.tags) do
      local higroup = underline_highlight_map[DiagnosticTag[tag]]
      if higroup then return higroup end
    end
  end
  local higroup = underline_highlight_map[DiagnosticSeverity[diagnostic.severity]]
  if higroup then return higroup end
  return underline_highlight_map[DiagnosticSeverity.Error]  -- fallback
end


if not lsp.diagnostic.set_qflist then
  -- Exact copy of <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/diagnostic.lua#L1193-L1229>,
  -- but for the quickfix list. NOTE: in this function the `workspace` option
  -- is set by default.
  -- See also: <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/handlers.lua#L194-L199>.
  -- UPDATE: This was actually added to the upstream in <https://github.com/neovim/neovim/pull/14831>.
  function lsp.diagnostic.set_qflist(opts)
    opts = opts or {}
    local open_qflist = utils.if_nil(opts.open_qflist, true)
    local workspace = utils.if_nil(opts.workspace, true)  -- added
    local current_bufnr = vim.api.nvim_get_current_buf()
    local diags = workspace and lsp.diagnostic.get_all(opts.client_id) or {
      [current_bufnr] = lsp.diagnostic.get(current_bufnr, opts.client_id)
    }
    local severity = M.to_severity(opts.severity)
    local severity_limit = M.to_severity(opts.severity_limit)
    local items = lsp.util.diagnostics_to_items(diags, function(d)
      if severity then return d.severity == severity end
      if severity_limit then return d.severity <= severity_limit end
      return true
    end)
    local title = 'Language Server diagnostics from ' .. vim.fn.expand('%:.')
    lsp.util.set_qflist(items, { title = title })  -- changed
    if open_qflist then
      vim.api.nvim_command('copen')  -- changed
    end
  end
end


-- Copied from <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/util.lua#L35-L40>.
M.LOCLIST_TYPE_MAP = {
  [DiagnosticSeverity.Error] = 'E',
  [DiagnosticSeverity.Warning] = 'W',
  [DiagnosticSeverity.Information] = 'I',
  -- This could use `N`: <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/util.lua#L39>,
  -- see <https://github.com/neovim/neovim/blob/v0.5.0/src/nvim/quickfix.c#L147>.
  [DiagnosticSeverity.Hint] = 'N',
}


-- Copy of <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/util.lua#L1890-L1920>,
-- plus some formatting. See also <https://github.com/neoclide/coc.nvim/blob/0ad03ca857ae9ea30e51d7d8317096e1d378aa41/src/list/source/diagnostics.ts#L26-L30>.
function lsp.util.diagnostics_to_items(diagnostics_by_bufnr, predicate)
  local items = {}
  for bufnr, diagnostics in pairs(diagnostics_by_bufnr or {}) do
    for _, d in pairs(diagnostics) do
      if not predicate or predicate(d) then
        local filename = vim.api.nvim_buf_get_name(bufnr)
        -- This block is the changed part.
        -- See also: <https://github.com/neovim/neovim/pull/14736/files#r646134919>
        local linenr, colnr = lsp_utils.position_to_linenr_colnr(bufnr, d.range.start)
        table.insert(items, {
          filename = filename,
          bufnr = bufnr,
          lnum = linenr + 1,
          col = colnr + 1,
          type = M.LOCLIST_TYPE_MAP[d.severity or DiagnosticSeverity.Error] or 'E',
          text = string.format('[%s %s] %s', d.source or 'LS', d.code or '?', d.message),
        })
      end
    end
  end
  table.sort(items, function(a, b)
    if a.filename ~= b.filename then
      return a.filename < b.filename
    elseif a.lnum ~= b.lnum then
      return a.lnum < b.lnum
    else
      return a.col < b.col
    end
  end)
  return items
end


local orig_diagnostic_save = lsp.diagnostic.save
function lsp.diagnostic.save(diagnostics, bufnr, client_id, ...)
  if diagnostics then
    local client_name = lsp_utils.try_get_client_name(client_id)
    -- <https://github.com/neoclide/coc.nvim/blob/c49acf35d8c32c16e1f14ab056a15308e0751688/src/diagnostic/collection.ts#L47-L51>
    for _, diagnostic in ipairs(diagnostics) do
      if diagnostic.severity == nil then diagnostic.severity = DiagnosticSeverity.Error end
      if diagnostic.message == nil then diagnostic.message = 'unknown diagnostic message' end
      if diagnostic.source == nil then diagnostic.source = client_name end
    end
  end
  return orig_diagnostic_save(diagnostics, bufnr, client_id, ...)
end


-- Patched version of <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/diagnostic.lua#L1115-L1173>.
-- See also <https://github.com/neoclide/coc.nvim/blob/3de26740c2d893191564dac4785002e3ebe01c3a/src/diagnostic/manager.ts#L449-L471>
-- and <https://github.com/neoclide/coc.nvim/blob/3de26740c2d893191564dac4785002e3ebe01c3a/data/schema.json#L651-L655>.
function lsp.diagnostic.show_line_diagnostics(opts, bufnr, line_nr, client_id)
  opts = opts or {}
  bufnr = bufnr or 0
  line_nr = line_nr or (vim.api.nvim_win_get_cursor(0)[1] - 1)

  local line_diagnostics = lsp.diagnostic.get_line_diagnostics(bufnr, line_nr, opts, client_id)
  if vim.tbl_isempty(line_diagnostics) then return end

  -- The changed block.
  opts.max_width = opts.max_width or lsp_global_settings.DIAGNOSTIC_WINDOW_MAX_WIDTH
  opts.max_height = opts.max_height or lsp_global_settings.DIAGNOSTIC_WINDOW_MAX_HEIGHT

  local lines = {}
  local highlights = {}
  local get_severity_highlight = lsp.diagnostic._get_floating_severity_highlight_name
  local fallback_severity_highlight = get_severity_highlight(DiagnosticSeverity.Error)

  for d_idx, d in ipairs(line_diagnostics) do
    if d_idx > 1 then
      -- table.insert(lines, string.rep('─', opts.max_width))
      -- table.insert(highlights, '')
    end

    local higroup = get_severity_highlight(d.severity) or fallback_severity_highlight
    local message = string.format(
      '[%s %s] [%s] %s', d.source or 'LS', d.code or '?', DiagnosticSeverity[d.severity][1] or 'E', d.message
    )
    for _, message_line in ipairs(vim.split(message, '\n', true)) do
      table.insert(lines, message_line)
      table.insert(highlights, higroup)
    end
  end
  -- End of the changes.

  opts.focus_id = 'line_diagnostics'
  local popup_bufnr, winid = lsp.util.open_floating_preview(lines, 'plaintext', opts)
  for i, higroup in ipairs(highlights) do
    if higroup ~= '' then
      vim.api.nvim_buf_add_highlight(popup_bufnr, -1, higroup, i - 1, 0, -1)
    end
  end

  return popup_bufnr, winid
end


-- Based (to some extent) on <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/diagnostic.lua#L462-L496>
-- and <https://github.com/neovim/neovim/blob/48e67b229415b4e2b3315bd00b817e5f9ab970c8/runtime/lua/vim/diagnostic.lua#L442-L481>,
-- but otherwise this should be an original implementation.
function M.get_neighbor(forward, opts)
  opts = opts or {}
  local winid = opts.win_id or vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_win_get_buf(winid)
  local cursor_linenr, cursor_colnr =
    utils.unpack2(opts.cursor_position or vim.api.nvim_win_get_cursor(winid))
  local cursor_pos = lsp_utils.linenr_colnr_to_position(bufnr, cursor_linenr - 1, cursor_colnr)
  local cursor_range = { start = cursor_pos, ['end'] = cursor_pos }
  local wrap = utils.if_nil(opts.wrap, true)

  local compare_direction = forward and 1 or -1
  local function compare_ranges(a, b)
    local a_start, b_start = a.start, b.start
    if a_start.line ~= b_start.line then
      return (a_start.line - b_start.line) * compare_direction
    else
      return (a_start.character - b_start.character) * compare_direction
    end
  end

  local severity = M.to_severity(opts.severity)
  local severity_limit = M.to_severity(opts.severity_limit)

  local closest_next_diag = nil
  local furthest_wrap_diag = nil

  for _, diag in ipairs(lsp.diagnostic.get(bufnr, opts.client_id)) do
    if severity and diag.severity ~= severity then goto continue end
    if severity_limit and diag.severity > severity_limit then goto continue end
    local ordering = compare_ranges(diag.range, cursor_range)
    if ordering > 0 then  -- diag.range > cursor_range
      -- after
      if closest_next_diag == nil or compare_ranges(diag.range, closest_next_diag.range) < 0 then
        closest_next_diag = diag
      end
    elseif wrap and ordering < 0 then  -- diag.range < cursor_range
      -- before
      if furthest_wrap_diag == nil or compare_ranges(diag.range, furthest_wrap_diag.range) <= 0 then
        furthest_wrap_diag = diag
      end
    end
    ::continue::
  end

  if closest_next_diag == nil and wrap then
    return furthest_wrap_diag
  end
  return closest_next_diag
end

function lsp.diagnostic.get_prev(opts)
  local diag = M.get_neighbor(false, opts)
  return diag and {diag}
end

function lsp.diagnostic.get_next(opts)
  local diag = M.get_neighbor(true, opts)
  return diag and {diag}
end

-- Based on <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/diagnostic.lua#L498-L514>.
function M.get_neighbor_pos(forward, opts)
  opts = opts or {}
  local winid = opts.win_id or vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_win_get_buf(winid)
  local diag = M.get_neighbor(forward, opts)
  if not diag then
    return false
  end
  return {lsp_utils.position_to_linenr_colnr(bufnr, diag.range.start)}
end

function lsp.diagnostic.get_prev_pos(opts)
  return M.get_neighbor_pos(false, opts)
end

function lsp.diagnostic.get_next_pos(opts)
  return M.get_neighbor_pos(true, opts)
end

-- Based on <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/diagnostic.lua#L516-L537>.
function M.jump_to_neighbor(forward, opts)
  opts = opts or {}
  local pos = M.get_neighbor_pos(forward, opts)
  if not pos then
    lsp_utils.client_notify(opts.client_id, 'no more diagnostics to jump to', vim.log.levels.WARN)
    return false
  end
  local winid = opts.win_id or vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_cursor(winid, {pos[1] + 1, pos[2]})
  if utils.if_nil(opts.foldopen, true) then
    vim.cmd('normal! zv')
  end
  if utils.if_nil(opts.enable_popup, true) then
    -- Shrug, don't ask me why schedule() is needed. Ask the Nvim maintainers:
    -- <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/diagnostic.lua#L532>.
    vim.schedule(function()
      lsp.diagnostic.show_line_diagnostics(opts.popup_opts, vim.api.nvim_win_get_buf(winid))
    end)
  end
  return true
end

function lsp.diagnostic.goto_prev(opts)
  return M.jump_to_neighbor(false, opts)
end

function lsp.diagnostic.goto_next(opts)
  return M.jump_to_neighbor(true, opts)
end


-- This one is a little bit too domain-specfic... Based on
-- <https://github.com/neoclide/coc.nvim/blob/eb47e40c52e21a5ce66bee6e51f1fafafe18a232/src/diagnostic/buffer.ts#L225-L253>.
function M.get_severity_stats_for_statusline(bufnr)
  local severities = {
    DiagnosticSeverity.Error,
    DiagnosticSeverity.Warning,
    DiagnosticSeverity.Information,
    DiagnosticSeverity.Hint,
  }
  local diag_counts = {}
  local diag_first_lines = {}
  for _, severity in ipairs(severities) do
    diag_counts[severity] = 0
    diag_first_lines[severity] = -1
  end
  local any_clients_attached = false
  lsp.for_each_buffer_client(bufnr, function(client)
    any_clients_attached = true
    -- NOTE: `lsp.diagnostic.get_count` on Nvim 0.6.0 invokes
    -- `lsp.diagnostic.get` instead of caching like it does on 0.5.0, so for
    -- future-proofing's sake it is better to not use it at all and do the
    -- counting in one loop.
    for _, diagnostic in ipairs(lsp.diagnostic.get(bufnr, client.id)) do
      local severity = diagnostic.severity
      if not (type(severity) == 'number' and DiagnosticSeverity[severity]) then
        severity = DiagnosticSeverity.Error
      end
      diag_counts[severity] = diag_counts[severity] + 1
      local line = diagnostic.range.start.line + 1
      local min_first_line = diag_first_lines[severity]
      diag_first_lines[severity] = min_first_line >= 0 and math.min(min_first_line, line) or line
    end
  end)
  if any_clients_attached then
    local vim_result = { count = {}, first_line = {} }
    for i, severity in ipairs(severities) do
      vim_result.count[i] = diag_counts[severity]
      vim_result.first_line[i] = diag_first_lines[severity]
    end
    return vim_result
  end
end


return M
