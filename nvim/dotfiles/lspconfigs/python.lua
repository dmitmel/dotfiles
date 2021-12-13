-- <https://github.com/fannheyward/coc-pyright/blob/master/src/index.ts>
-- TODO: reimplement good chunk of coc-pyright

local lsp = require('vim.lsp')
local lsp_ignition = require('dotfiles.lsp.ignition')
local lspconfig_utils = require('lspconfig.util')
local vim_uri = require('vim.uri')
local rplugin_bridge = require('dotfiles.rplugin_bridge')
local utils = require('dotfiles.utils')
local lsp_utils = require('dotfiles.lsp.utils')

local DOTFILES_DIR = vim.fn.fnamemodify(utils.script_path(), ':p:h:h:h:h')

local python_filetypes = {'python'}
lsp_ignition.setup_config('pyright', {
  cmd = {'pyright-langserver', '--stdio'};
  filetypes = python_filetypes;
  -- root_dir = lspconfig_utils.root_pattern('pyproject.toml', 'pyrightconfig.json', 'Pipfile', 'setup.py', 'setup.cfg', 'requirements.txt');
  single_file_support = true;
  completion_menu_label = 'Py';

  settings_scopes = {'python', 'pyright'};
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true;
        useLibraryCodeForTypes = true;
        diagnosticMode = 'workspace';
        -- typeCheckingMode = 'strict';
      }
    };
  };

  on_init = function(client)
    local orig_rpc_request = client.rpc.request
    function client.rpc.request(method, params, handler, ...)
      local orig_handler = handler
      if method == 'textDocument/completion' then
        -- Idiotic take on <https://github.com/fannheyward/coc-pyright/blob/6a091180a076ec80b23d5fc46e4bc27d4e6b59fb/src/index.ts#L90-L107>.
        handler = function(...)
          local err, result = ...
          if not err and result then
            local items = result.items or result
            for _, item in ipairs(items) do
              if not (item.data and item.data.funcParensDisabled) and (
                item.kind == lsp.protocol.CompletionItemKind.Function or
                item.kind == lsp.protocol.CompletionItemKind.Method or
                item.kind == lsp.protocol.CompletionItemKind.Constructor
              ) then
                item.insertText = item.label .. '($1)$0'
                item.insertTextFormat = lsp.protocol.InsertTextFormat.Snippet
              end
            end
          end
          return orig_handler(...)
        end
      end
      return orig_rpc_request(method, params, handler, ...)
    end
  end;

  vim_user_commands = {
    -- <https://github.com/fannheyward/coc-pyright/blob/6a091180a076ec80b23d5fc46e4bc27d4e6b59fb/src/index.ts#L204-L208>
    LspPyrightRestartServer = {handler = function(_, client)
      client.request(
        'workspace/executeCommand',
        { command = 'pyright.restartserver' },
        lsp_utils.wrap_handler_errors(function(_, _, _) end)
      )
    end};

    -- <https://github.com/fannheyward/coc-pyright/blob/6a091180a076ec80b23d5fc46e4bc27d4e6b59fb/src/index.ts#L189-L202>
    -- <https://github.com/neovim/nvim-lspconfig/blob/7c5ce01c20adb707ca9f13f3a60d1d3915905bc3/lua/lspconfig/pyright.lua#L10-L16>
    LspPyrightOrganizeImports = {handler = function(_, client, bufnr)
      client.request(
        'workspace/executeCommand',
        { command = 'pyright.organizeimports', arguments = {vim.uri_from_bufnr(bufnr)} },
        lsp_utils.wrap_handler_errors(function(_, _, _) end)
      )
    end};
  };
})


lsp_ignition.setup_config('yapf', {
  filetypes = python_filetypes;
  -- root_dir = lspconfig_utils.root_pattern('pyproject.toml', '.style.yapf', 'Pipfile', 'setup.py', 'setup.cfg', 'requirements.txt');
  single_file_support = true;

  virtual_server = {
    capabilities = {
      documentFormattingProvider = true;
      documentRangeFormattingProvider = true;
    };
    on_init = function()
      rplugin_bridge.notify('python3', 'init', {})
    end;
    handlers = (function()
      local function real_formatting_handler(is_ranged, reply, _, params, _, vserver)
        local buf_uri = params.textDocument.uri
        local bufnr = vim_uri.uri_to_bufnr(buf_uri)
        assert(vim.api.nvim_buf_is_loaded(bufnr))
        local buf_path = utils.uri_maybe_to_fname(buf_uri)
        local buf_root_dir = vserver.root_dir or vim.fn.getcwd()
        local default_config_path = DOTFILES_DIR .. '/misc/yapf.ini'
        local buf_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)
        local fmt_ranges = nil
        if is_ranged then
          fmt_ranges = {{params.range.start.line + 1, params.range['end'].line + 1}}
        end

        local rpc_result = rplugin_bridge.request('python3', 'lsp_formatter_yapf', utils.nil_pack(
          buf_path, buf_root_dir, default_config_path, fmt_ranges, buf_lines
        ))
        if rpc_result == nil or rpc_result == vim.NIL then
          return reply(nil, nil)
        end

        local common_lines_from_start, common_lines_from_end, fmt_lines = utils.unpack3(rpc_result)
        local one_big_text_edit = {
          -- NOTE: CALCULATE FROM buf_lines!!!
          range = {
            start = { line = common_lines_from_start, character = 0 },
            ['end'] = { line = #buf_lines - common_lines_from_end, character = 0 },
          },
          -- NOTE: CALCULATE FROM fmt_lines!!!
          newText = table.concat(vim.tbl_map(function(line) return line .. '\n' end, fmt_lines)),
        }
        return reply(nil, {one_big_text_edit})
      end
      return {
        ['textDocument/formatting'] = function(...)
          return real_formatting_handler(false, ...)
        end,
        ['textDocument/rangeFormatting'] = function(...)
          return real_formatting_handler(true, ...)
        end,
      }
    end)();
  };
})
