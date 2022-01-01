--- Primarily patches to <https://github.com/neovim/neovim/blob/v0.6.0/runtime/lua/vim/diagnostic.lua>
--- and <https://github.com/neovim/neovim/blob/v0.6.0/runtime/lua/vim/lsp/diagnostic.lua>.
---
--- TODO: Contribute these to the upstream! This is of utmost importance.
local M = require('dotfiles.autoload')('dotfiles.lsp.diagnostics')

local vim_diagnostic = require('vim.diagnostic')
local Severity = vim_diagnostic.severity
local utils = require('dotfiles.utils')
local lsp = require('vim.lsp')
local utils_vim = require('dotfiles.utils.vim')
local lsp_global_settings = require('dotfiles.lsp.global_settings')
local lsp_utils = require('dotfiles.lsp.utils')

M.ALL_SEVERITIES = { Severity.ERROR, Severity.WARN, Severity.INFO, Severity.HINT }

M.SEVERITY_NAMES = {
  [Severity.ERROR] = 'error',
  [Severity.WARN] = 'warning',
  [Severity.INFO] = 'info',
  [Severity.HINT] = 'hint',
}

-- Copied from <https://github.com/neovim/neovim/blob/v0.6.0/runtime/lua/vim/diagnostic.lua#L191-L207>.
local function make_highlight_map(base_name)
  local result = {}
  for _, severity in ipairs(M.ALL_SEVERITIES) do
    local name = Severity[severity]
    result[severity] = 'Diagnostic' .. base_name .. name:sub(1, 1) .. name:sub(2):lower()
  end
  return result
end
M.virtual_text_highlight_map = make_highlight_map('VirtualText')
M.underline_highlight_map = make_highlight_map('Underline')
M.floating_highlight_map = make_highlight_map('Floating')
M.sign_highlight_map = make_highlight_map('Sign')

M.underline_tag_highlight_map = {}
for name, tag in pairs(lsp.protocol.DiagnosticTag) do
  if type(name) == 'string' then
    M.underline_tag_highlight_map[tag] = 'DiagnosticUnderline' .. name
  end
end

--- Stolen from <https://github.com/neovim/neovim/blob/v0.6.0/runtime/lua/vim/diagnostic.lua#L68-L74>.
function M.to_severity(severity)
  if type(severity) == 'string' then
    return assert(
      M.severity[string.upper(severity)],
      string.format('Invalid severity: %s', severity)
    )
  end
  return severity
end

--- Stolen from <https://github.com/neovim/neovim/blob/v0.6.0/runtime/lua/vim/diagnostic.lua#L76-L91>.
function M.filter_by_severity(severity, diagnostics)
  if not severity then
    return diagnostics
  end
  if type(severity) ~= 'table' then
    severity = M.to_severity(severity)
    return vim.tbl_filter(function(t)
      return t.severity == severity
    end, diagnostics)
  end
  local min_severity = M.to_severity(severity.min) or M.severity.HINT
  local max_severity = M.to_severity(severity.max) or M.severity.ERROR
  return vim.tbl_filter(function(t)
    return t.severity <= min_severity and t.severity >= max_severity
  end, diagnostics)
end

-- Copied from <https://github.com/neovim/neovim/blob/v0.6.0/runtime/lua/vim/diagnostic.lua#L962-L998>
-- See also <https://github.com/neoclide/coc.nvim/blob/705135211e84725766e434f59e63ae3592c609d9/src/diagnostic/buffer.ts#L255-L264>
function vim_diagnostic._get_virt_text_chunks(line_diags, opts)
  if #line_diags == 0 then
    return nil
  end

  opts = opts or {}
  local prefix = opts.prefix or '#'
  local spacing = opts.spacing or 4

  local virt_texts = { { string.rep(' ', spacing) } }

  local main_diag = line_diags[#line_diags]
  table.insert(virt_texts, { ' ', M.virtual_text_highlight_map[main_diag.severity] })
  for i = #line_diags, 1, -1 do
    local diag = line_diags[i]
    table.insert(virt_texts, { prefix, M.virtual_text_highlight_map[diag.severity] })
  end

  local str = ' '
  if main_diag.message then
    str = ' ' .. main_diag.message:gsub('\r', ' \\ '):gsub('\n', ' \\ ') .. ' '
  end
  table.insert(virt_texts, { str, M.virtual_text_highlight_map[main_diag.severity] })

  return virt_texts
end

local orig_underline_handler_show = vim_diagnostic.handlers.underline.show
-- Replacement for <https://github.com/neovim/neovim/blob/v0.6.0/runtime/lua/vim/diagnostic.lua#L859-L897>.
-- Handles LSP DiagnosticTags, see <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#diagnosticTag>.
function vim_diagnostic.handlers.underline.show(namespace, bufnr, diagnostics, opts, ...)
  vim.validate({
    namespace = { namespace, 'number' },
    bufnr = { bufnr, 'number' },
    diagnostics = { diagnostics, 'table' },
    opts = { opts, 'table', true },
  })

  bufnr = utils_vim.normalize_bufnr(bufnr)

  if opts.underline and opts.underline.severity then
    diagnostics = M.filter_by_severity(opts.underline.severity, diagnostics)
  end

  local ns = vim_diagnostic.get_namespace(namespace)
  if not ns.user_data.underline_ns then
    ns.user_data.underline_ns = vim.api.nvim_create_namespace('')
  end

  for _, diagnostic in ipairs(diagnostics) do
    vim.highlight.range(
      bufnr,
      ns.user_data.underline_ns,
      -- The changed part (abstracted in a function):
      M.get_underline_highlight_group(diagnostic),
      { diagnostic.lnum, diagnostic.col },
      { diagnostic.end_lnum, diagnostic.end_col }
    )
  end

  -- The original handler must still be run afterwards because it includes some
  -- logic for saving extmarks, available only via local functions. This is
  -- most likely a fix for some bug, so we want our extmarks to be saved too,
  -- but not for the original handler to create new extmarks, so we <del>patch
  -- out the `vim.highlight.range` function that it uses and still call
  -- it</del> on a second thought, no checking is performed to see if the
  -- diagnostics list is empty, so let's just call it with an empty table. Note
  -- that the `hide` function of the handler deletes the saved extmarks, but we
  -- don't need to override it since it is working just fine from our
  -- perspective.
  return orig_underline_handler_show(namespace, bufnr, {}, opts, ...)
end

-- See also: <https://github.com/neoclide/coc.nvim/blob/705135211e84725766e434f59e63ae3592c609d9/src/diagnostic/buffer.ts#L342-L362>
function M.get_underline_highlight_group(diagnostic)
  for _, tag in ipairs(((diagnostic.user_data or {}).lsp or {}).tags or {}) do
    local higroup = M.underline_tag_highlight_map[tag]
    if higroup then
      return higroup
    end
  end
  local higroup = M.underline_highlight_map[diagnostic.severity]
  if higroup then
    return higroup
  end
  return M.underline_highlight_map[Severity.ERROR] -- fallback
end

--- Based on <https://github.com/neovim/neovim/blob/v0.6.0/runtime/lua/vim/diagnostic.lua#L434-L456>.
function M.set_list(loclist, opts)
  opts = opts or {}
  local winnr, bufnr
  if loclist then
    winnr = opts.winnr or 0
    bufnr = vim.api.nvim_win_get_buf(winnr)
  end
  local title = opts.title or ('Diagnostics from ' .. vim.fn.expand('%:.'))
  local items = vim_diagnostic.toqflist(vim_diagnostic.get(bufnr, opts))
  utils_vim.echo({ { string.format('Found %d diagnostics', #items) } })
  vim.call('dotfiles#utils#push_qf_list', {
    title = title,
    dotfiles_loclist_window = winnr,
    dotfiles_auto_open = opts.open,
    items = items,
  })
end

--- Replaces <https://github.com/neovim/neovim/blob/v0.6.0/runtime/lua/vim/diagnostic.lua#L1335-L1344>.
function vim_diagnostic.setqflist(opts)
  return M.set_list(false, opts)
end

--- Replaces <https://github.com/neovim/neovim/blob/v0.6.0/runtime/lua/vim/diagnostic.lua#L1346-L1356>.
function vim_diagnostic.setloclist(opts)
  return M.set_list(true, opts)
end

-- Copied from <https://github.com/neovim/neovim/blob/v0.6.0/runtime/lua/vim/diagnostic.lua#L1484-L1489>.
M.LOCLIST_TYPE_MAP = {
  [Severity.ERROR] = 'E',
  [Severity.WARN] = 'W',
  [Severity.INFO] = 'I',
  [Severity.HINT] = 'N',
}

-- Copy of <https://github.com/neovim/neovim/blob/v0.6.0/runtime/lua/vim/diagnostic.lua#L1491-L1520>,
-- plus some formatting. See also <https://github.com/neoclide/coc.nvim/blob/0ad03ca857ae9ea30e51d7d8317096e1d378aa41/src/list/source/diagnostics.ts#L26-L30>.
function vim_diagnostic.toqflist(diagnostics)
  vim.validate({
    diagnostics = { diagnostics, 'table' },
  })
  local items = {}
  for i, v in pairs(diagnostics) do
    items[i] = {
      bufnr = v.bufnr,
      lnum = v.lnum + 1,
      col = v.col and (v.col + 1) or nil,
      end_lnum = v.end_lnum and (v.end_lnum + 1) or nil,
      end_col = v.end_col and (v.end_col + 1) or nil,
      type = M.LOCLIST_TYPE_MAP[v.severity] or 'E',
      -- The only changed part:
      text = M.format_diagnostic_for_list(v),
    }
  end
  table.sort(items, function(a, b)
    if a.filename ~= b.filename then
      return a.filename < b.filename
    elseif a.lnum ~= b.lnum then
      return a.lnum < b.lnum
    else
      -- Also I've added sorting by the column number
      return a.col < b.col
    end
  end)
  return items
end

function M.format_diagnostic_for_list(diag)
  local meta = {}
  table.insert(meta, diag.source)
  table.insert(meta, ((diag.user_data or {}).lsp or {}).code)
  local text = diag.message:gsub('\n', ' \\ '):gsub('\r', ' \\ ')
  if #meta > 0 then
    text = '[' .. table.concat(meta, ' ') .. '] ' .. vim.trim(text)
  else
    text = vim.trim(text)
  end
  return text
end

function vim_diagnostic.fromqflist(list)
  vim.validate({
    list = { list, 'table' },
  })
  -- TODO: Because I apply some formatting to the diagnostic messages in
  -- toqflist, this will have to handle that and parse the original message.
  error('not yet implemented')
end

function M.patch_lsp_diagnostics(diagnostics, client_id)
  local client = lsp.get_client_by_id(client_id)
  -- <https://github.com/neoclide/coc.nvim/blob/c49acf35d8c32c16e1f14ab056a15308e0751688/src/diagnostic/collection.ts#L47-L51>
  for _, diag in ipairs(diagnostics) do
    if diag.severity == nil then
      diag.severity = lsp.protocol.DiagnosticSeverity.Error
    end
    if diag.message == nil then
      diag.message = 'unknown diagnostic message'
    end
    if diag.source == nil then
      diag.source = client.name
    end
  end
end

local orig_lsp_diagnostic_save = lsp.diagnostic.save
function lsp.diagnostic.save(diagnostics, bufnr, client_id, ...)
  if diagnostics then
    M.patch_lsp_diagnostics(diagnostics, client_id)
  end
  return orig_lsp_diagnostic_save(diagnostics, bufnr, client_id, ...)
end

-- This function must be completely replaced to use my `get_buf_lines_batch`.
-- The default implementation uses a local function for some reason with much
-- simpler logic even in comparison to `lsp.util.get_lines` through
-- `diagnostic_lsp_to_vim`. There are other functions which use that converter
-- function, but they are all deprecated, so I don't bother patching them. The
-- code was copied from <https://github.com/neovim/neovim/blob/v0.6.1/runtime/lua/vim/lsp/diagnostic.lua#L156-L210>.
function lsp.diagnostic.on_publish_diagnostics(err, result, ctx, config, ...)
  if not err and result and result.diagnostics and ctx.client_id then
    M.patch_lsp_diagnostics(result.diagnostics, ctx.client_id)
  end
  if config ~= nil then
    error('TODO: configuration of on_publish_diagnostics is disabled')
  end
  local bufnr = vim.uri_to_bufnr(result.uri)
  local client_id = utils.if_nil(ctx.client_id, -1)
  local namespace = lsp.diagnostic.get_namespace(client_id)
  vim_diagnostic.set(namespace, bufnr, M.convert_lsp_to_vim(result.diagnostics, bufnr, client_id))
end

-- Copied from <https://github.com/neovim/neovim/blob/v0.6.1/runtime/lua/vim/lsp/diagnostic.lua#L91-L118>.
function M.convert_lsp_to_vim(lsp_diagnostics, bufnr, client_id)
  local client = lsp.get_client_by_id(client_id)
  local enc = client and client.offset_encoding

  local lines_request = {}
  for _, diag in ipairs(lsp_diagnostics) do
    lines_request[diag.range.start.line] = true
    lines_request[diag.range['end'].line] = true
  end
  lsp_utils.get_buf_lines_batch(bufnr, lines_request)

  local vim_diagnostics = {}
  for i, diag in ipairs(lsp_diagnostics) do
    local start_pos, end_pos = diag.range.start, diag.range['end']
    local start_text, end_text = lines_request[start_pos.line], lines_request[end_pos.line]
    local start_col = lsp_utils.char_offset_to_byte_offset(start_pos.character, start_text, enc)
    local end_col = lsp_utils.char_offset_to_byte_offset(end_pos.character, end_text, enc)
    vim_diagnostics[i] = {
      lnum = start_pos.line,
      col = start_col,
      end_lnum = end_pos.line,
      end_col = end_col,
      message = diag.message,
      severity = diag.severity,
      source = diag.source,
      user_data = {
        lsp = {
          code = diag.code,
          codeDescription = diag.codeDescription,
          tags = diag.tags,
          relatedInformation = diag.relatedInformation,
          data = diag.data,
        },
      },
    }
  end

  return vim_diagnostics
end

-- NOTE: <https://github.com/neovim/neovim/pull/16520>
-- NOTE: But still, I added the logging of the current diagnostic, I must PR that (TODO)
-- Copied from <https://github.com/neovim/neovim/blob/v0.6.0/runtime/lua/vim/diagnostic.lua#L499-L528>.
function M.jump_to_neighbor(opts, diag)
  if not diag then
    utils_vim.echomsg({ { 'No more valid diagnostics to move to', 'WarningMsg' } })
    return false
  end

  opts = opts or {}
  local float = utils.if_nil(opts.float, true)
  local winid = opts.win_id or vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_win_get_buf(winid)

  vim.api.nvim_win_call(winid, function()
    -- Save position in the window's jumplist
    vim.cmd("normal! m'")
    vim.api.nvim_win_set_cursor(winid, { diag.lnum + 1, diag.col })
    vim.cmd('normal! zv')
  end)

  -- This is inefficient
  local matching_diags = vim_diagnostic.get(bufnr, opts)
  table.sort(matching_diags, function(a, b)
    if a.lnum == b.lnum then
      return a.col < b.col
    end
    return a.lnum < b.lnum
  end)
  local current_idx = nil
  for idx, diag2 in ipairs(matching_diags) do
    if rawequal(diag2, diag) then
      current_idx = idx
    end
  end
  if current_idx then
    local message = string.format(
      '(%d of %d) %s: %s',
      current_idx,
      #matching_diags,
      M.SEVERITY_NAMES[diag.severity],
      M.format_diagnostic_for_list(diag)
    )
    utils_vim.echo({ { message } })
  end

  if float then
    if type(float) ~= 'table' then
      float = {}
    end
    -- Shrug, don't ask me why schedule() is needed. Ask the Nvim maintainers:
    -- <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/diagnostic.lua#L532>.
    vim.schedule(function()
      vim_diagnostic.open_float(
        bufnr,
        vim.tbl_extend('keep', float, { scope = 'cursor', focus = false })
      )
    end)
  end
end

function vim_diagnostic.goto_prev(opts)
  return M.jump_to_neighbor(opts, vim_diagnostic.get_prev(opts))
end

function vim_diagnostic.goto_next(opts)
  return M.jump_to_neighbor(opts, vim_diagnostic.get_next(opts))
end

-- This one is a little bit too domain-specfic... Based on
-- <https://github.com/neoclide/coc.nvim/blob/eb47e40c52e21a5ce66bee6e51f1fafafe18a232/src/diagnostic/buffer.ts#L225-L253>.
function M.get_severity_stats_for_statusline(bufnr, diagnostics)
  diagnostics = diagnostics or vim_diagnostic.get(bufnr)
  local severities = {
    Severity.ERROR,
    Severity.WARN,
    Severity.INFO,
    Severity.HINT,
  }
  local diag_counts = {}
  local diag_first_lines = {}
  for _, severity in ipairs(severities) do
    diag_counts[severity] = 0
    diag_first_lines[severity] = -1
  end
  for _, diagnostic in ipairs(diagnostics) do
    local severity = diagnostic.severity
    diag_counts[severity] = diag_counts[severity] + 1
    local line = diagnostic.lnum + 1
    local min_first_line = diag_first_lines[severity]
    diag_first_lines[severity] = min_first_line >= 0 and math.min(min_first_line, line) or line
  end
  local vim_result = { count = {}, first_line = {} }
  for i, severity in ipairs(severities) do
    vim_result.count[i] = diag_counts[severity]
    vim_result.first_line[i] = diag_first_lines[severity]
  end
  return vim_result
end

-- Thank God the handlers system exists, it makes my life so much easier.
vim_diagnostic.handlers['dotfiles/statusline_stats'] = {
  show = function(_, bufnr, diagnostics, _)
    local stats = M.get_severity_stats_for_statusline(bufnr, diagnostics)
    vim.api.nvim_buf_set_var(bufnr, 'dotfiles_lsp_diagnostics_statusline_stats', stats)
  end,
  hide = function(_, bufnr)
    vim.api.nvim_buf_set_var(bufnr, 'dotfiles_lsp_diagnostics_statusline_stats', vim.NIL)
  end,
}

-- And now, for the cherry on the cake. Even I've gotta admit, configuring the
-- system declaratively like this instead of hundreds of lines of
-- monkey-patches feels pretty Nice.
vim_diagnostic.config({
  float = {
    header = '', -- Turn the header off
    prefix = '',
    format = M.format_diagnostic_for_list,
    severity_sort = false,
    max_width = lsp_global_settings.DIAGNOSTIC_WINDOW_MAX_WIDTH,
    max_height = lsp_global_settings.DIAGNOSTIC_WINDOW_MAX_HEIGHT,
  },
  underline = true,
  virtual_text = {
    prefix = '#',
    spacing = 1,
  },
  signs = {
    priority = 10, -- De-conflict with vim-signify.
  },
  severity_sort = true,
})

return M
