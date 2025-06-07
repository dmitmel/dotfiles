local has_diagnostic, vim_diagnostic = pcall(require, 'vim.diagnostic')
if not has_diagnostic then return end

local utils = require('dotfiles.utils')
local Severity = vim_diagnostic.severity

---@param name string
---@return table<vim.diagnostic.Severity, string>
local function make_highlight_map(name)
  return {
    [Severity.ERROR] = 'Diagnostic' .. name .. 'Error',
    [Severity.WARN] = 'Diagnostic' .. name .. 'Warn',
    [Severity.INFO] = 'Diagnostic' .. name .. 'Info',
    [Severity.HINT] = 'Diagnostic' .. name .. 'Hint',
  }
end

vim_diagnostic.config({
  severity_sort = true,

  jump = {
    float = true,
  },

  float = {
    header = '', -- Turn the header off
    prefix = '',
    border = utils.border_styles.hpad,
    severity_sort = false,

    suffix = function(diagnostic)
      local meta = {}
      -- `table.insert` with `nil` will not do anything to the list. I use
      -- this trick to effectively filter out the nil entries.
      table.insert(meta, diagnostic.source)
      table.insert(meta, diagnostic.code)
      local space = diagnostic.message:find('\n') and '\n' or ' '
      local text = #meta > 0 and (space .. '(' .. table.concat(meta, ' ') .. ')') or ''
      return text, 'NormalFloat'
    end,
  },

  underline = true,

  virtual_text = {
    spacing = 1,
    prefix = function(diagnostic)
      local s = diagnostic.severity
      return (s == Severity.WARN or s == Severity.ERROR) and '!' or '*'
    end,

    -- How coc.nvim does virtual text formatting:
    -- <https://github.com/neoclide/coc.nvim/blob/0449efb6908aec786cb9548fad90ab3a9c931c9a/src/diagnostic/buffer.ts#L560-L566>
    format = function(diagnostic)
      -- This pattern extracts the first non-empty line.
      return diagnostic.message:match('([^\r\n]*%S[^\r\n]*)') or diagnostic.message
      -- return diagnostic.message:gsub('[\r\n]+', ' \\ ')
    end,
  },

  signs = {
    priority = 10, -- De-conflict with vim-signify.
    text = {
      [Severity.ERROR] = 'XX',
      [Severity.WARN] = '!!',
      [Severity.INFO] = '##',
      [Severity.HINT] = '>>',
    },
    linehl = make_highlight_map('Line'),
    numhl = make_highlight_map('LineNr'),
  },
})

utils.augroup('dotfiles_diagnostics'):autocmd(
  'DiagnosticChanged',
  utils.schedule_once_per_frame(function() vim.cmd('redrawstatus!') end),
  { desc = 'redraw the statusline on diagnostics updates' }
)

-- NOTE: the patches below are unused
do
  return
end

vim.cmd('hi def link DiagnosticFloatWin NormalFloat')
vim_diagnostic._open_float_orig = vim_diagnostic._open_float_orig or vim_diagnostic.open_float
function vim_diagnostic.open_float(...) ---@diagnostic disable-line: duplicate-set-field
  local function patch_float(bufnr, winid, ...)
    vim.fn.win_execute(winid, 'setlocal winhl+=NormalFloat:DiagnosticFloatWin')
    return bufnr, winid, ...
  end
  return patch_float(vim_diagnostic._open_float_orig(...))
end

local handlers = vim_diagnostic.handlers
---@diagnostic disable-next-line: inject-field
handlers.signs._old_show = handlers.signs._old_show or handlers.signs.show
function handlers.signs.show(namespace, bufnr, diagnostics, opts)
  handlers.signs._old_show(namespace, bufnr, diagnostics, opts)

  local culhl = opts.signs.culhl ---@diagnostic disable-line: undefined-field

  if not vim.api.nvim_buf_is_loaded(bufnr) or culhl == nil then return end

  local sign_ns = vim_diagnostic.get_namespace(namespace).user_data.sign_ns
  for _, diagnostic in ipairs(diagnostics) do
    local extmarks = vim.api.nvim_buf_get_extmarks(
      bufnr,
      sign_ns,
      { diagnostic.lnum, 0 },
      { diagnostic.lnum, -1 },
      { details = true }
    )
    for _, extmark in ipairs(extmarks) do
      local id, row, col, details = unpack(extmark, 1, 4)
      details.cursorline_hl_group = culhl[diagnostic.severity]
      details.id = id
      details.ns_id = nil
      vim.api.nvim_buf_set_extmark(bufnr, sign_ns, row, col, details)
    end
  end
end

local diagnostic_patch_lsp_client_id = nil

vim_diagnostic._old_set = vim_diagnostic._old_set or vim_diagnostic.set
---@diagnostic disable-next-line: duplicate-set-field
function vim_diagnostic.set(namespace, bufnr, diagnostics, opts)
  local lsp = require('vim.lsp')
  local lsp_extras = require('dotfiles.lsp_extras')

  -- <https://github.com/neovim/neovim/blob/v0.11.0/runtime/lua/vim/lsp/diagnostic.lua#L73-L112>
  if diagnostic_patch_lsp_client_id ~= nil then
    local client = lsp.get_client_by_id(diagnostic_patch_lsp_client_id)
    local position_encoding = client and client.offset_encoding or 'utf-16'

    local lines_request = {} ---@type table<integer, string>
    for _, vim_diag in ipairs(diagnostics) do
      local lsp_diag = vim_diag.user_data.lsp ---@type lsp.Diagnostic?
      if lsp_diag then
        lines_request[lsp_diag.range.start.line] = ''
        lines_request[lsp_diag.range['end'].line] = ''
      end
    end

    local ok = lsp_extras.get_buf_lines_batch(bufnr, lines_request)
    if ok then
      for _, vim_diag in ipairs(diagnostics) do
        local lsp_diag = vim_diag.user_data.lsp ---@type lsp.Diagnostic?
        if lsp_diag then
          local start, end_ = lsp_diag.range.start, lsp_diag.range['end']
          vim_diag.col =
            vim.str_byteindex(lines_request[start.line], position_encoding, start.character, false)
          vim_diag.end_col =
            vim.str_byteindex(lines_request[end_.line], position_encoding, end_.character, false)
        end
      end
    end
  end
  return vim_diagnostic._old_set(namespace, bufnr, diagnostics, opts)
end

lsp.handlers['textDocument/diagnostic'] = function(error, params, ctx)
  diagnostic_patch_lsp_client_id = ctx.client_id
  lsp.diagnostic.on_diagnostic(error, params, ctx)
  diagnostic_patch_lsp_client_id = nil
end

lsp.handlers['textDocument/publishDiagnostics'] = function(error, params, ctx)
  diagnostic_patch_lsp_client_id = ctx.client_id
  lsp.diagnostic.on_publish_diagnostics(error, params, ctx)
  diagnostic_patch_lsp_client_id = nil
end
