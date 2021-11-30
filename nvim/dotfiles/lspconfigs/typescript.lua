-- See also:
-- <https://github.com/neoclide/coc-tsserver/blob/master/src/index.ts>
-- <https://github.com/neoclide/coc-eslint/blob/master/src/index.ts>

-- TODO: custom server for prettier
-- TODO TODO TODO: <https://github.com/fsouza/prettierd/blob/main/src/service.ts>

local lsp = require('vim.lsp')
local lspconfig = require('lspconfig')
local lsp_utils = require('dotfiles.lsp.utils')

lspconfig['tsserver'].setup({
  completion_menu_label = 'TS';

  init_options = {
    disableAutomaticTypingAcquisition = true;
  };

  settings_scopes = {'tsserver', 'javascript', 'typescript'};
  settings = {
    typescript = {
      format = false;
    };
    javascript = {
      format = false;
    };
  };

  on_init = function(client)
    client.resolved_capabilities.document_formatting = false
    client.resolved_capabilities.document_range_formatting = false
  end;
})

local function eslint_fix_all(client, bufnr)
  client.request_sync('workspace/executeCommand', {
    command = 'eslint.applyAllFixes',
    arguments = {lsp_utils.make_versioned_text_document_params(bufnr)},
  }, nil, bufnr)
end

lspconfig['eslint'].setup({
  settings_scopes = {'eslint'};

  handlers = {
    ['eslint/openDoc'] = lsp_utils.wrap_handler_errors(function(result, ctx, config)
      assert(type(result.url) == 'string')
      vim.call('dotfiles#utils#open_url', result.url)
      return vim.NIL
    end)
  };

  ignition_commands = {
    LspEslintFixAll = {handler = function(_, client, bufnr)
      return eslint_fix_all(client, bufnr)
    end}
  };
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
