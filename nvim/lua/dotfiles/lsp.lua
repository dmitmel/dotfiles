local M = require('dotfiles.autoload')('dotfiles.lsp')

local lsp = require('vim.lsp')
local lspconfig = require('lspconfig')
local lsp_basic_handlers = require('dotfiles.lsp.basic_handlers')
local lsp_diagnostic = require('dotfiles.lsp.diagnostics')
local lsp_float = require('dotfiles.lsp.float')
local lsp_global_settings = require('dotfiles.lsp.global_settings')
local lsp_hover = require('dotfiles.lsp.hover')
local lsp_markup = require('dotfiles.lsp.markup')
local lsp_progress = require('dotfiles.lsp.progress')
local lsp_signature_help = require('dotfiles.lsp.signature_help')
local lsp_symbols = require('dotfiles.lsp.symbols')
local lsp_utils = require('dotfiles.lsp.utils')

-- TODO: copy server configurations
-- TODO: reimplement good chunk of coc-pyright
-- TODO: unsort items from get_line_diagnostics <https://github.com/neovim/neovim/pull/14372#issuecomment-825806392> <https://github.com/neovim/neovim/commit/4de404a681426f9d5a1253ca7bc97b075ca14bee>


-- TODO: distribute capability and handler installations across modules
-- TODO: get rid of this central module and require() everything from completion.vim

local default_capabilities = vim.tbl_deep_extend('force', lsp.protocol.make_client_capabilities(), {
  textDocument = {
    -- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#completionClientCapabilities>
    completion = vim.call('dotfiles#plugman#is_registered', 'nvim-compe') and {
      completionItem = {
        snippetSupport = true;
        resolveSupport = {
          properties = {'documentation', 'detail', 'additionalTextEdits'};
        };
      };
    } or nil;
    -- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#signatureHelpClientCapabilities>
    signatureHelp = {
      signatureInformation = {
        activeParameterSupport = true;
        parameterInformation = {
          labelOffsetSupport = true;
        };
      };
    };
  };
  window = {
    workDoneProgress = true;
  };
})
if vim.call('dotfiles#plugman#is_registered', 'cmp-nvim-lsp') then
  default_capabilities = require('cmp_nvim_lsp').update_capabilities(default_capabilities)
end


lspconfig.util.default_config = vim.tbl_deep_extend('force', lspconfig.util.default_config, {
  capabilities = default_capabilities;
  flags = {
    debounce_text_changes = 100;
  };

  handlers = {

    ['textDocument/hover'] = lsp_utils.wrap_handler_compat(lsp_hover.handler);
    ['textDocument/signatureHelp'] = lsp_utils.wrap_handler_compat(lsp_signature_help.handler);

    ['textDocument/publishDiagnostics'] = lsp.with(lsp.handlers['textDocument/publishDiagnostics'], {
      underline = true,
      virtual_text = {
        prefix = '#',
        spacing = 1,
      },
      signs = {
        priority = 10,  -- De-conflict with vim-signify.
      },
      severity_sort = true,
    });

    ['textDocument/declaration'] = lsp_utils.wrap_handler_compat(lsp_basic_handlers.declaration_handler);
    ['textDocument/definition'] = lsp_utils.wrap_handler_compat(lsp_basic_handlers.definition_handler);
    ['textDocument/typeDefinition'] = lsp_utils.wrap_handler_compat(lsp_basic_handlers.definition_handler);
    ['textDocument/implementation'] = lsp_utils.wrap_handler_compat(lsp_basic_handlers.implementation_handler);
    ['textDocument/references'] = lsp_utils.wrap_handler_compat(lsp_basic_handlers.references_handler);

    ['textDocument/documentSymbol'] = lsp_utils.wrap_handler_compat(lsp_symbols.handler);
    ['workspace/symbol'] = lsp_utils.wrap_handler_compat(lsp_symbols.handler);

  };
})


return M
