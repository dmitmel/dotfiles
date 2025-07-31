local has_lsp, lsp = pcall(require, 'vim.lsp')
if not (has_lsp and lsp.config ~= nil and vim.g.vim_ide == 2) then return end

local utils = require('dotfiles.utils')
local lsp_log = require('vim.lsp.log') -- This was not exported until Nvim 0.9
local lsp_extras = require('dotfiles.lsp_extras')

lsp_log.set_format_func(function(arg) return vim.inspect(arg, { newline = ' ', indent = '' }) end)
lsp_log.set_level(utils.if_nil(lsp_log.levels[vim.env.NVIM_LSP_LOG], lsp_log.levels.WARN))

require('dotfiles.lsp_ignition').enable({
  'lua_ls',
  'rust_analyzer',
  'clangd',
  'cssls',
  'html',
  'jsonls',
  'yamlls',
  'basedpyright',
  'eslint',
  'vtsls',
  'ruff',
  'prettier',
})

vim.api.nvim_create_user_command('LspLog', function(cmd) --
  vim.cmd.edit({ lsp.get_log_path(), bang = cmd.bang, mods = cmd.smods })
end, { bar = true, bang = true })

vim.api.nvim_create_user_command('LspInfo', 'checkhealth vim.lsp', { bar = true })
vim.cmd("execute dotutils#cmd_alias('LI', 'LspInfo')")

if dotplug.has('conform.nvim') then
  require('conform').setup({
    default_format_opts = {
      lsp_format = 'fallback',
    },
    formatters_by_ft = {
      lua = { 'stylua' },
    },
  })
end

local has_conform, conform = pcall(require, 'conform')
local lsp_format = has_conform and conform.format or lsp.buf.format

local complete_formatters = utils.command_completion_fn(function()
  local bufnr = vim.api.nvim_get_current_buf()
  local names = {} ---@type string[]
  for _, formatter in ipairs(has_conform and conform.list_formatters(bufnr) or {}) do
    names[#names + 1] = formatter.name
  end
  for _, client in ipairs(lsp.get_clients({ bufnr = bufnr, method = 'textDocument/formatting' })) do
    names[#names + 1] = client.name
  end
  return names
end)

vim.api.nvim_create_user_command('LspFormat', function(cmd) --
  lsp_format({
    name = #cmd.args > 0 and cmd.args or nil,
    async = false,
    range = cmd.range ~= 0 and {
      start = { cmd.line1, 0 },
      ['end'] = { cmd.line2, vim.fn.col({ cmd.line2, '$' }) - 1 },
    } or nil,
  })
end, { bar = true, range = true, nargs = '?', complete = complete_formatters })

-- TODO: support more things than just eslint?
vim.api.nvim_create_user_command('LspFixAll', function()
  local bufnr = vim.api.nvim_get_current_buf()
  for _, client in ipairs(lsp.get_clients({ name = 'eslint', bufnr = bufnr })) do
    if lsp_extras.client_has_diagnostics(client.id, bufnr) then
      client:request_sync('workspace/executeCommand', {
        command = 'eslint.applyAllFixes',
        arguments = { lsp_extras.make_versioned_text_document_params(bufnr) },
      }, nil, bufnr)
    end
  end
end, { bar = true })

local map = vim.keymap.set

map({ 'n', 'x' }, '<space>f', function() --
  lsp_format({ async = false })
end, { desc = 'lsp.buf.format()' })

-- A new table with floating options has to be created every time because the
-- functions that will be using it mutate its contents.
local function floating_preview_opts()
  return {
    offset_x = -1,
    max_width = 80,
    max_height = 24,
    border = utils.border_styles.hpad,
  }
end

map('n', '<F2>', lsp.buf.rename, { desc = 'lsp.buf.rename()' })
map({ 'n', 'x' }, '<A-CR>', lsp.buf.code_action, { desc = 'lsp.buf.code_action()' })
map({ 'n', 'x' }, '<space>a', lsp.buf.code_action, { desc = 'lsp.buf.code_action()' })
local function signature_help() lsp.buf.signature_help(floating_preview_opts()) end
map('n', '<space>s', signature_help, { desc = 'lsp.buf.signature_help()' })
map('i', '<F1>', signature_help, { desc = 'lsp.buf.signature_help()' })
map('n', '<space>K', function() lsp_extras.hover(floating_preview_opts()) end, {
  desc = 'lsp.buf.hover()',
})

vim.cmd('hi def link DiagnosticFloat NormalFloat')
vim.cmd('hi def link DiagnosticFloatBorder FloatBorder')

map('n', '<A-d>', function()
  local _, float_win = vim.diagnostic.open_float({ scope = 'line' })
  if float_win then
    vim.api.nvim_win_call(float_win, function()
      -- Right now this is the easiest way of modifying `winhl`. Change my mind.
      vim.cmd('setlocal winhl+=NormalFloat:DiagnosticFloat,FloatBorder:DiagnosticFloatBorder')
    end)
  end
end, { desc = 'vim.diagnostic.open_float()' })

-- The mnemonic here is "dia[g]nostic". Very intuitive, I know, but `]d` and
-- `[d` are taken by the line duplication mappings. The previous mappings for
-- diagnostics jumps used `c`, which meant 'coc', obviously, but that one is
-- taken by the mappings for Git hunk jumps, and I really wanted to untangle
-- those two.
map('n', '[g', function() --
  vim.diagnostic.jump({ count = -vim.v.count1, wrap = true })
end, { desc = 'jump to the previous diagnostic' })

map('n', ']g', function() --
  vim.diagnostic.jump({ count = vim.v.count1, wrap = true })
end, { desc = 'jump to the next diagnostic' })

map('n', '[G', function() --
  vim.diagnostic.jump({ count = -math.huge, wrap = false })
end, { desc = 'jump to the last diagnostic' })

map('n', ']G', function() --
  vim.diagnostic.jump({ count = math.huge, wrap = false })
end, { desc = 'jump to the first diagnostic' })

map('n', '<space>gd', function() --
  lsp_extras.jump('textDocument/definition', 'definitions', { exclude_current = true })
end, { desc = 'lsp.buf.definition()' })

map('n', '<space>gD', function() --
  lsp_extras.jump('textDocument/declaration', 'declarations', { exclude_current = true })
end, { desc = 'lsp.buf.declaration()' })

map('n', '<space>gt', function() --
  lsp_extras.jump('textDocument/typeDefinition', 'type definitions', { exclude_current = true })
end, { desc = 'lsp.buf.type_definition()' })

map('n', '<space>gi', function() --
  lsp_extras.jump('textDocument/implementation', 'implementations', { exclude_current = true })
end, { desc = 'lsp.buf.implementation()' })

map('n', '<space>gr', function() --
  lsp_extras.jump('textDocument/references', 'references', {
    context = { includeDeclaration = true },
  })
end, { desc = 'lsp.buf.references()' })

if dotplug.has('fzf-lua') then
  local fzf = require('fzf-lua')
  map('n', '<space>d', fzf.diagnostics_workspace, { desc = 'Pick diagnostics' })
  map('n', '<space>o', fzf.lsp_document_symbols, { desc = 'Pick LSP document symbols' })
  map('n', '<space>w', fzf.lsp_live_workspace_symbols, { desc = 'Pick LSP workspace symbols' })
  map('n', '<space>c', function() fzf.commands({ query = '^Lsp ' }) end)
elseif dotplug.has('snacks.nvim') then
  local pick = require('snacks.picker')
  map('n', '<space>d', pick.diagnostics, { desc = 'Pick diagnostics' })
  map('n', '<space>o', pick.lsp_symbols, { desc = 'Pick LSP document symbols' })
  map('n', '<space>w', pick.lsp_workspace_symbols, { desc = 'Pick LSP workspace symbols' })
  map('n', '<space>c', function() pick.commands({ pattern = '^Lsp ' }) end)
else
  map('n', '<space>d', function() --
    vim.diagnostic.setqflist({ severity = { min = vim.diagnostic.severity.INFO } })
  end, { desc = 'vim.diagnostic.setqflist()' })
  map('n', '<space>o', lsp.buf.document_symbol, { desc = 'lsp.buf.document_symbol()' })
  map('n', '<space>w', lsp.buf.workspace_symbol, { desc = 'lsp.buf.workspace_symbol()' })
  map('n', '<space>c', function() return ':<C-u>Lsp<C-z>' end, { expr = true })
end

local function lsp_supports(method) ---@param method string
  return #lsp.get_clients({ bufnr = 0, method = method }) > 0
end

-- Create shorthands overriding Vim's default mappings which make sense when a
-- language server is connected. Note that these are not created in `on_attach`
-- or similar so that the client checks checks will correctly respond to the
-- server being stopped or detached.
map('n', 'gd', function() --
  return lsp_supports('textDocument/definition') and '<space>gd' or 'gd'
end, { expr = true, desc = 'lsp.buf.definition()', remap = true })

map('n', 'gD', function() --
  return lsp_supports('textDocument/declaration') and '<space>gD' or 'gD'
end, { expr = true, desc = 'lsp.buf.declaration()', remap = true })

map('n', 'gO', function() --
  return lsp_supports('textDocument/documentSymbol') and '<space>o' or 'gO'
end, { expr = true, desc = 'lsp.buf.document_symbol()', remap = true })

-- <nowait> is necessary here because starting from v0.11 Neovim defines many
-- default mappings starting with `gr`:
-- <https://github.com/neovim/neovim/blob/v0.11.0/runtime/lua/vim/_defaults.lua#L196-L210>.
map('n', 'gr', function() --
  return lsp_supports('textDocument/references') and '<space>gr' or ''
end, { expr = true, desc = 'lsp.buf.references()', remap = true, nowait = true })

vim.keymap.set('n', 'K', function()
  if utils.is_truthy(vim.g.dotfiles_vimspector_active) then
    return '<Plug>VimspectorBalloonEval'
  elseif lsp_supports('textDocument/hover') then
    return '<space>K'
  else
    return 'K'
  end
end, { expr = true, remap = true })

if dotplug.has('neoconf.nvim') and utils.has('vim_starting') then
  local neoconf_util = require('neoconf.util')
  local neoconf_config = require('neoconf.config')

  -- Patch neoconf to search for global configs not only in `stdpath("config")`,
  -- but also in all runtime directories.
  -- <https://github.com/folke/neoconf.nvim/blob/33880483b4ca91fef04d574b9c8b8cca88061c8f/lua/neoconf/util.lua#L216-L228>
  -- <https://github.com/folke/neoconf.nvim/blob/33880483b4ca91fef04d574b9c8b8cca88061c8f/lua/neoconf/import.lua>
  ---@param fn fun(file: string, key:string|nil, pattern:string)
  function neoconf_util.for_each_global(fn)
    for _, p in ipairs(neoconf_config.global_patterns) do
      for _, f in ipairs(vim.api.nvim_get_runtime_file(p.pattern, true)) do
        fn(f, (type(p.key) == 'function' and p.key(f) or p.key) --[[@as string]], p.pattern)
      end
    end
  end

  require('neoconf').setup({
    import = {
      vscode = true,
      coc = true,
      nlsp = true,
    },
  })
end

if dotplug.has('fidget.nvim') then
  local fidget = require('fidget')

  fidget.setup({
    progress = {
      -- ignore_done_already = true,
      display = {
        done_ttl = 2, -- seconds
      },
    },
    notification = {
      window = {
        align = 'bottom',
      },
    },
  })

  ---@type table<vim.lsp.protocol.Method, boolean>
  local NOISY_LSP_REQUESTS = {
    ['textDocument/documentHighlight'] = true,
    ['textDocument/semanticTokens/full'] = true,
    ['textDocument/semanticTokens/full/delta'] = true,
    ['textDocument/semanticTokens/range'] = true,
    ['textDocument/completion'] = true,
    ['completionItem/resolve'] = true,
    ['textDocument/diagnostic'] = true,
  }

  -- This displays in-progress LSP requests with fidget.nvim. Inspired by
  -- <https://github.com/j-hui/fidget.nvim/issues/246#issuecomment-2658595412>.
  utils.augroup('dotfiles_lsp'):autocmd('LspRequest', function(args)
    local request, request_id, client_id =
      args.data.request, args.data.request_id, args.data.client_id
    if NOISY_LSP_REQUESTS[request.method] then return end

    -- TODO: Handle cancelled requests correctly.
    local request_status_to_message = {
      pending = 'Requesting',
      error = 'Error',
      complete = 'Completed',
      cancel = 'Cancelled',
    }

    ---@type ProgressMessage
    local message = {
      title = request.method,
      message = request_status_to_message[request.type],
      lsp_client = lsp.get_client_by_id(client_id) or {},
      cancellable = false,
      done = request.type ~= 'pending',
      token = ('%s:%s'):format(client_id, request_id),
    }

    fidget.progress.load_config(message)
    fidget.notify(fidget.progress.format_progress(message))
  end)
end

lsp.util._old_open_floating_preview = lsp.util._old_open_floating_preview
  or lsp.util.open_floating_preview
--- This patch updates positions of the floating windows created by
--- `vim.lsp.util.open_floating_preview()` when the parent window is scrolled,
--- effectively "anchoring" them to the cursor.
function lsp.util.open_floating_preview(contents, syntax, opts)
  local parent_win = vim.api.nvim_get_current_win()
  local parent_buf = vim.api.nvim_get_current_buf()
  local float_buf, float_win = lsp.util._old_open_floating_preview(contents, syntax, opts)

  local augroup = utils.augroup('dotfiles.lsp_float_scroll_' .. float_win, { clear = true })

  -- This event is also triggered when a window is resized, so having an
  -- autocommand for |WinResized| is redundant.
  augroup:autocmd('WinScrolled', function()
    if not vim.api.nvim_win_is_valid(float_win) or not vim.api.nvim_win_is_valid(parent_win) then
      return true -- delete this autocommand
    end
    -- `v:event` is a dictionary containing all affected windows, see |WinScrolled-event|.
    if vim.v.event[tostring(parent_win)] ~= nil then
      vim.api.nvim_win_call(parent_win, function()
        local width = vim.api.nvim_win_get_width(float_win)
        local height = vim.api.nvim_win_get_height(float_win)
        -- This function needs too be called within `parent_win`.
        local float_opts = lsp.util.make_floating_popup_options(width, height, opts)
        vim.api.nvim_win_set_config(float_win, float_opts)
      end)
    end
  end)

  -- This is a fix for <https://github.com/neovim/neovim/issues/34945> which was
  -- introduced briefly only in version v0.11.3, but my fix also makes the
  -- floating window close instantly. The `nested` flag is necessary to fire the
  -- `WinClosed` event to do the cleanup.
  augroup:autocmd('BufEnter', function(event)
    if event.buf ~= float_buf and event.buf ~= parent_buf then
      pcall(vim.api.nvim_win_close, float_win, true)
    end
  end, { nested = true })

  augroup:autocmd('WinClosed', tostring(float_win), function() --
    augroup:delete()
  end, { once = true })

  return float_buf, float_win
end

vim.api.nvim_create_user_command('LspHoverDebug', function()
  local function make_params(client) ---@param client vim.lsp.Client
    return lsp.util.make_position_params(0, client.offset_encoding)
  end
  local responses = assert(lsp.buf_request_sync(0, 'textDocument/hover', make_params --[[@as any]]))
  for client_id, res in pairs(responses) do
    local client = lsp.get_client_by_id(client_id)
    if res.result and not res.error and client then
      print(client.name or client_id, vim.inspect(res.result))
    end
  end
end, { bar = true })

--- A complete replacement of this function using my own markdown renderer.
---@param bufnr integer
---@param contents string[]
---@param opts? vim.lsp.util.open_floating_preview.Opts
---@see dotfiles.markdown.renderer
function lsp.util.stylize_markdown(bufnr, contents, opts)
  opts = opts or {}

  local renderer = require('dotfiles.markdown').renderer.new()
  renderer:parse_markdown_section(table.concat(contents, '\n'))
  local lines = renderer:get_lines()

  local width = lsp.util._make_floating_popup_size(lines, opts)
  if opts.wrap_at then
    width = math.min(width, opts.wrap_at)
  elseif vim.wo.wrap then
    width = math.min(width, vim.api.nvim_win_get_width(0))
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, lines)
  renderer:highlight_markdown(bufnr, width)
  renderer:highlight_code_blocks(bufnr)
end

--- Replacement for <https://github.com/saghen/blink.cmp/blob/v1.3.1/lua/blink/cmp/lib/window/docs.lua>
---@param opts blink.cmp.RenderDetailAndDocumentationOpts
require('blink.cmp.lib.window.docs').render_detail_and_documentation = function(opts)
  local details = opts.detail
  if type(details) ~= 'table' then details = { details } end

  local renderer = require('dotfiles.markdown').renderer.new()

  local seen_details = {}
  for _, v in ipairs(details) do
    if #v > 0 and not seen_details[v] then
      seen_details[v] = true
      renderer:parse_plaintext_section(v, vim.bo.filetype)
    end
  end

  if opts.documentation then
    local separator_line = renderer.linenr + 1
    renderer:parse_documentation_sections(opts.documentation)
    if renderer.lines[separator_line] == '' then
      renderer.lines_separators[separator_line] = true
    end
  end

  vim.api.nvim_buf_set_lines(opts.bufnr, 0, -1, true, renderer:get_lines())
  vim.bo[opts.bufnr].modified = false

  if opts.use_treesitter_highlighting then
    renderer:highlight_markdown(opts.bufnr, opts.max_width)
    -- HACK: This is a really dumb fix for a bug that happens when the
    -- documentation window is first opened: a buffer is prepared with the text
    -- before the popup window is created, and the code for opening a floating
    -- window sets the `filetype` of the buffer[1], which causes `syntax clear`
    -- to be run and resets the code block regions my highlighter has defined.
    -- To fix this, I didn't come up with anything better than just delaying
    -- the creation of `syntax` regions with `vim.schedule()`.
    -- [1]: <https://github.com/Saghen/blink.cmp/blob/v1.3.1/lua/blink/cmp/lib/window/init.lua#L136>
    if #vim.fn.win_findbuf(opts.bufnr) == 0 then
      vim.schedule(function() renderer:highlight_code_blocks(opts.bufnr) end)
    else
      renderer:highlight_code_blocks(opts.bufnr)
    end
  end
end

--- I patch this function to use `xpcall` instead of `pcall` to show full backtraces.
---@param cbs function[]
---@param error_id integer
---@param ... any
---@diagnostic disable-next-line: invisible
function lsp.client:_run_callbacks(cbs, error_id, ...)
  -- THE ORIGINAL SOURCE CODE USES `pairs` HERE!!!
  for _, callback in ipairs(cbs) do
    local ok, err = xpcall(callback, debug.traceback, ...)
    if not ok then
      local code = lsp.client_errors[error_id]
      local prefix = self._log_prefix ---@diagnostic disable-line: invisible
      local err_first_line = string.match(err, '^([^\n]*)')
      lsp.log.error(prefix, 'on_error', { code = code, err = err_first_line })
      local notify = vim.in_fast_event() and vim.schedule_wrap(vim.notify) or vim.notify
      notify(('%s: Error %s: %s'):format(prefix, code, err), vim.log.levels.ERROR)
    end
  end
end
