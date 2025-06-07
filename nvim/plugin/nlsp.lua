local has_lsp, lsp = pcall(require, 'vim.lsp')
if not (has_lsp and lsp.config ~= nil and vim.g.vim_ide == 2) then return end

local utils = require('dotfiles.utils')
local lsp_log = require('vim.lsp.log') -- This was not exported until Nvim 0.9
local lsp_extras = require('dotfiles.lsp_extras')

lsp_log.set_format_func(function(arg) return vim.inspect(arg, { newline = ' ', indent = '' }) end)
lsp_log.set_level(utils.if_nil(lsp_log.levels[vim.env.NVIM_LSP_LOG], lsp_log.levels.WARN))

-- TODO: rename to :LspLog once I get rid of nvim-lspconfig
vim.api.nvim_create_user_command('LspOpenLog', function(cmd) --
  vim.cmd.edit({ lsp.get_log_path(), bang = cmd.bang, mods = cmd.smods })
end, { bar = true, bang = true })

vim.api.nvim_create_user_command('LspInfo', 'checkhealth vim.lsp', { bar = true })
vim.cmd("execute dotutils#cmd_alias('LI', 'LspInfo')")

local has_conform, conform = pcall(require, 'conform')
local lsp_format = has_conform and conform.format or lsp.buf.format

vim.api.nvim_create_user_command('LspFormat', function(cmd) --
  lsp_format({
    async = not cmd.bang,
    range = cmd.range ~= 0 and {
      start = { cmd.line1, 0 },
      ['end'] = { cmd.line2, vim.fn.col({ cmd.line2, '$' }) - 1 },
    } or nil,
  })
end, { bar = true, bang = true, range = true })

local map = vim.keymap.set

map({ 'n', 'x' }, '<space>f', function() --
  lsp_format({ async = false })
end, { desc = 'lsp.buf.format()' })

map('n', '<F2>', lsp.buf.rename, { desc = 'lsp.buf.rename()' })
map({ 'n', 'x' }, '<A-CR>', lsp.buf.code_action, { desc = 'lsp.buf.code_action()' })
map({ 'n', 'x' }, '<space>a', lsp.buf.code_action, { desc = 'lsp.buf.code_action()' })
map('n', '<space>s', lsp.buf.signature_help, { desc = 'lsp.buf.signature_help()' })
map('i', '<F1>', lsp.buf.signature_help, { desc = 'lsp.buf.signature_help()' })
map('n', '<space>o', lsp.buf.document_symbol, { desc = 'lsp.buf.document_symbol()' })
map('n', '<space>w', lsp.buf.workspace_symbol, { desc = 'lsp.buf.workspace_symbol()' })

map('n', '<space>K', function() --
  lsp.buf.hover({ max_width = 80, max_height = 24, border = utils.border_styles.hpad })
end, { desc = 'lsp.buf.hover()' })

vim.cmd('hi def link DiagnosticFloat NormalFloat')
vim.cmd('hi def link DiagnosticFloatBorder FloatBorder')
local diagnostic_float_winhl =
  'setlocal winhl+=NormalFloat:DiagnosticFloat,FloatBorder:DiagnosticFloatBorder'

map('n', '<A-d>', function() --
  local _, winid = vim.diagnostic.open_float({ max_width = 80, max_height = 8 })
  if winid then vim.fn.win_execute(winid, diagnostic_float_winhl) end
end, { desc = 'vim.diagnostic.open_float()' })

map('n', '<space>d', function() --
  vim.diagnostic.setqflist({ severity = { min = vim.diagnostic.severity.INFO } })
end, { desc = 'vim.diagnostic.setqflist()' })

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
elseif dotplug.has('snacks.nvim') then
  local pick = require('snacks.picker')
  map('n', '<space>d', pick.diagnostics, { desc = 'Pick diagnostics' })
  map('n', '<space>o', pick.lsp_symbols, { desc = 'Pick LSP document symbols' })
  map('n', '<space>w', pick.lsp_workspace_symbols, { desc = 'Pick LSP workspace symbols' })
end

local function lsp_supports(method) ---@param method string
  return #vim.lsp.get_clients({ bufnr = 0, method = method }) > 0
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

if dotplug.has('neoconf.nvim') then
  -- NOTE: neoconf must be initialized BEFORE calling lspconfig.
  require('neoconf').setup({
    import = {
      vscode = true,
      coc = true,
      nlsp = true,
    },
  })
end

require('dotfiles.lsp_launcher').setup({
  'lua_ls',
  'rust_analyzer',
  'clangd',
  'cssls',
  'html',
  'jsonls',
  'yamlls',
  vim.fn.executable('basedpyright') ~= 0 and 'basedpyright' or 'pyright',
  'eslint',
  vim.fn.executable('vtsls') ~= 0 and 'vtsls' or 'ts_ls',
  'ruff',
})

vim.api.nvim_create_user_command('EslintFixAll', function(cmd)
  local bufnr = vim.api.nvim_get_current_buf()
  local params = {
    title = 'Fix all Eslint errors for current buffer',
    command = 'eslint.applyAllFixes',
    arguments = {
      { uri = vim.uri_from_bufnr(bufnr), version = lsp.util.buf_versions[bufnr] },
    },
  }
  for _, client in ipairs(lsp.get_clients({ name = 'eslint', bufnr = bufnr })) do
    if cmd.bang then
      local timeout = 3000
      -- Unfortunately, there is no `client:exec_cmd_sync` right now.
      client:request_sync('workspace/executeCommand', params, timeout, bufnr)
    else
      client:exec_cmd(params, { bufnr = bufnr })
    end
  end
end, { bar = true, bang = true })

-- NOTE: this file can be updated with `prettier --support-info > prettier_support_info.json`
local prettier_support_info =
  vim.json.decode(utils.read_file(utils.script_relative('../prettier_support_info.json')))

if dotplug.has('conform.nvim') then
  require('conform').setup((function()
    ---@type conform.setupOpts
    local opts = {
      default_format_opts = {
        lsp_format = 'fallback',
      },
      formatters_by_ft = {
        lua = { 'stylua' },
      },
      formatters = {
        prettierd = {
          -- TODO: dynamically derive default options from neoconf
          env = { PRETTIERD_DEFAULT_CONFIG = utils.script_relative('../../.prettierrc.json') },
        },
      },
    }

    for _, prettier_lang in ipairs(prettier_support_info.languages) do
      for _, ft in ipairs(prettier_lang.vscodeLanguageIds) do
        opts.formatters_by_ft[ft] = { 'prettierd', lsp_format = 'fallback' }
      end
    end

    return opts
  end)())
end

if dotplug.has('neoconf.nvim') then
  local neoconf_util = require('neoconf.util')
  local neoconf_config = require('neoconf.config')

  -- Patch neoconf to search for global configs not only in `stdpath("config")`,
  -- but also in all runtime directories.
  -- <https://github.com/folke/neoconf.nvim/blob/33880483b4ca91fef04d574b9c8b8cca88061c8f/lua/neoconf/util.lua#L216-L228>
  -- <https://github.com/folke/neoconf.nvim/blob/33880483b4ca91fef04d574b9c8b8cca88061c8f/lua/neoconf/import.lua>
  ---@param fn fun(file: string, key:string|nil, pattern:string)
  function neoconf_util.for_each_global(fn) ---@diagnostic disable-line: duplicate-set-field
    for _, p in ipairs(neoconf_config.global_patterns) do
      for _, f in ipairs(vim.api.nvim_get_runtime_file(p.pattern, true)) do
        fn(f, (type(p.key) == 'function' and p.key(f) or p.key) --[[@as string]], p.pattern)
      end
    end
  end

  require('neoconf.plugins').register({
    name = 'prettier',
    on_schema = function(schema)
      for _, opt in ipairs(prettier_support_info.options) do
        local key = 'prettier.' .. opt.name
        if opt.type == 'choice' then
          schema:set(key, {
            type = 'string',
            enum = utils.map(opt.choices, function(choice) return { choice.value } end),
            default = opt.default,
            description = opt.description,
          })
        elseif opt.type == 'boolean' then
          schema:set(key, { type = opt.type, default = opt.default, description = opt.description })
        elseif opt.type == 'int' then
          schema:set(key, { type = 'number', default = opt.default, description = opt.description })
        end
      end
    end,
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
        align = 'top',
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

    -- TODO: Handle canceled requests correctly.
    local request_status_to_message = {
      pending = 'Requesting',
      error = 'Error',
      complete = 'Completed',
      cancel = 'Canceled',
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
