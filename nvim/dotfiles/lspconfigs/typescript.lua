-- See also:
-- <https://github.com/neoclide/coc-tsserver/blob/master/src/index.ts>
-- <https://github.com/neoclide/coc-eslint/blob/master/src/index.ts>

-- TODO: custom server for prettier
-- TODO TODO TODO: <https://github.com/fsouza/prettierd/blob/main/src/service.ts>

local lsp_ignition = require('dotfiles.lsp.ignition')
local lspconfig_utils = require('lspconfig.util')
local lsp = require('vim.lsp')
local lsp_utils = require('dotfiles.lsp.utils')

local js_and_ts_filetypes = {
  'javascript',
  'javascriptreact',
  'javascript.jsx',
  'typescript',
  'typescriptreact',
  'typescript.jsx',
}
-- <https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/server_configurations/tsserver.lua>
lsp_ignition.setup_config('tsserver', {
  cmd = { 'typescript-language-server', '--stdio' },
  filetypes = js_and_ts_filetypes,
  -- root_dir = lspconfig_utils.root_pattern('tsconfig.json', 'jsconfig.json', 'package.json');
  completion_menu_label = 'TS',

  init_options = {
    hostInfo = 'neovim',
    disableAutomaticTypingAcquisition = true,
  },

  settings_scopes = {
    'tsserver',
    'javascript',
    'typescript',
    'completions.completeFunctionCalls',
    'diagnostics.ignoredCodes',
  },
  settings = {
    completions = {
      completeFunctionCalls = true,
    },
    typescript = {
      format = false,
    },
    javascript = {
      format = false,
    },
  },

  on_init = function(client)
    client.resolved_capabilities.document_formatting = false
    client.resolved_capabilities.document_range_formatting = false
  end,
})

local function eslint_fix_all(client, bufnr)
  client.request_sync('workspace/executeCommand', {
    command = 'eslint.applyAllFixes',
    arguments = { lsp_utils.make_versioned_text_document_params(bufnr) },
  }, nil, bufnr)
end

-- TODO: Don't re-use the nvim-lspconfig config here.
local lspconfig_eslint = require('lspconfig.server_configurations.eslint').default_config
-- <https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/server_configurations/eslint.lua>
lsp_ignition.setup_config('eslint', {
  cmd = { 'vscode-eslint-language-server', '--stdio' },
  filetypes = js_and_ts_filetypes,
  -- <https://eslint.org/docs/user-guide/configuring/configuration-files#configuration-file-formats>
  -- root_dir = lspconfig_utils.root_pattern('.eslintrc.js', '.eslintrc.cjs', '.eslintrc.yaml', '.eslintrc.yml', '.eslintrc.json', 'package.json');

  settings_scopes = { 'eslint' },
  -- <https://github.com/Microsoft/vscode-eslint#settings-options>
  settings = vim.tbl_deep_extend('force', lspconfig_eslint.settings, {}),

  on_new_config = function(final_config, root_dir)
    lspconfig_eslint.on_new_config(final_config, root_dir)
  end,

  handlers = vim.tbl_deep_extend('force', lspconfig_eslint.handlers, {
    ['eslint/openDoc'] = lsp_utils.wrap_handler_errors(function(result, ctx, config)
      assert(type(result.url) == 'string')
      vim.call('dotfiles#utils#open_url', result.url)
      return vim.NIL
    end),
  }),

  vim_user_commands = {
    LspEslintFixAll = {
      handler = function(_, client, bufnr)
        return eslint_fix_all(client, bufnr)
      end,
    },
  },
})

function _G.dotfiles._lsp_eslint_bufwritepre()
  local bufnr = vim.api.nvim_get_current_buf()
  for _, client in ipairs(lsp.buf_get_clients(bufnr)) do
    if client.name == 'eslint' then
      eslint_fix_all(client, bufnr)
    end
  end
end

vim.cmd([[
  augroup dotfiles_lsp_eslint
    autocmd!
    autocmd BufWritePre * call v:lua.dotfiles._lsp_eslint_bufwritepre()
  augroup END
]])
