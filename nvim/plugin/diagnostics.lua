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
    max_width = 80,
    max_height = 8,
    offset_x = -1,

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
    priority = 8,
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

local handlers = vim_diagnostic.handlers
handlers.signs._old_show = handlers.signs._old_show or handlers.signs.show
function handlers.signs.show(namespace, bufnr, diagnostics, opts)
  handlers.signs._old_show(namespace, bufnr, diagnostics, opts)

  local culhl = opts.signs.culhl ---@diagnostic disable-line: undefined-field
  if not culhl then return end

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
