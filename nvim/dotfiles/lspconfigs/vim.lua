-- <https://github.com/iamcco/coc-vimlsp/blob/master/src/index.ts>

local lsp = require('vim.lsp')
local lspconfig = require('lspconfig')
local lspconfig_vimls = require('lspconfig.server_configurations.vimls').default_config
local lsp_ignition = require('dotfiles.lsp.ignition')
local vim_uri = require('vim.uri')
local rplugin_bridge = require('dotfiles.rplugin_bridge')
local utils = require('dotfiles.utils')
local lsp_utils = require('dotfiles.lsp.utils')
local utils_vim = require('dotfiles.utils.vim')

lspconfig['vimls'].setup({
  -- Autocompletion for Vimscript turned out to be useless (no wonder).
  enabled = false;

  completion_menu_label = 'Vim';

  init_options = {
    isNeovim = utils_vim.has('nvim');
    vimruntime = vim.env.VIMRUNTIME;
    suggest = {
      fromVimruntime = true;
      fromRuntimepath = true;
    }
  };

  -- This hook is used to fill in the remaining initialization options
  -- because:
  --
  -- a) We get a chance to obtain a more accurate value of &iskeyword, after
  -- ftplugins for Vimscript (for the current buffer which caused attachment
  -- of the server) are run.
  --
  -- b) Some plugins may change runtimepath during loading. At least this was
  -- what prompted me to do a similar thing for this setup, but under coc.
  -- Oh, and initialization of runtimepath under packer was wonky at best...
  on_new_config = function(final_config, root_dir, bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local opts = final_config.init_options

    -- Check just to be sure. NOTE: This check is, as I've understood later,
    -- actually justified because bufnr might be nil.
    if (
      vim.tbl_contains(final_config.filetypes, vim.api.nvim_buf_get_option(bufnr, 'filetype'))
    ) then
      opts.iskeyword = vim.api.nvim_buf_get_option(bufnr, 'iskeyword')
    end

    opts.runtimepath = vim.o.runtimepath
  end;

  on_init = function(client)
    vim.schedule(function()
      function _G.dotfiles._lspconfigs_vim_autocmd_optionset_handler()
        local bufnr = vim.api.nvim_get_current_buf()
        if lsp.buf_is_attached(bufnr, client.id) then
          client.notify('$/change/iskeyword', vim.api.nvim_buf_get_option(bufnr, 'iskeyword'))
        end
      end
      vim.cmd([[
        augroup dotfiles_lsp_vimls
          autocmd!
          autocmd OptionSet iskeyword unsilent call v:lua.dotfiles._lspconfigs_vim_autocmd_optionset_handler()
        augroup END
      ]])
    end)
  end;

  on_exit = function()
    vim.schedule(function()
      _G.dotfiles._lspconfigs_vim_autocmd_optionset_handler = nil
      vim.cmd([[
        autocmd! dotfiles_lsp_vimls
        augroup! dotfiles_lsp_vimls
      ]])
    end)
  end;
})

lsp_ignition.setup_config('vint', {
  filetypes = lspconfig_vimls.filetypes;
  root_dir = lspconfig_vimls.root_dir;
  virtual_server = {
    capabilities = {
      textDocumentSync = {
        openClose = true;
        save = true;
      };
    };
    on_init = function()
      rplugin_bridge.notify('python3', 'init', {})
    end;
    handlers = (function()
      local function trigger_diagnostics(buf_uri, vserver)
        local bufnr = vim_uri.uri_to_bufnr(buf_uri)
        assert(vim.api.nvim_buf_is_loaded(bufnr))
        local buf_version = lsp.util.buf_versions[bufnr]
        local buf_path = utils.uri_maybe_to_fname(buf_uri)
        local buf_root_dir = vserver.root_dir or vim.fn.getcwd()
        local buf_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)

        local rpc_result = rplugin_bridge.request('python3', 'lsp_linter_vint', utils.nil_pack(
          buf_path, buf_root_dir, buf_lines
        ))
        if rpc_result == nil or rpc_result == vim.NIL then
          return
        end

        local DiagnosticSeverity = lsp.protocol.DiagnosticSeverity
        -- See <https://github.com/Vimjas/vint/blob/v0.3.21/vint/linting/level.py>.
        local VINT_LEVEL_TO_LSP_SEVERITY = {
          [0] = DiagnosticSeverity.Error,    -- ERROR
          [1] = DiagnosticSeverity.Warning,  -- WARNING
          [2] = DiagnosticSeverity.Warning,  -- STYLE_PROBLEM
        }

        local diagnostics = {}
        for idx, item in ipairs(rpc_result) do
          -- NOTE: colnr is already in UTF-8 offsets because that's what the
          -- vimlparser library returns. That's because the Python port is
          -- automatically compiled from the Vimscript version, and we all know
          -- what Vimscript uses for line and column numbers. And also they are
          -- 1-based, for the same reason.
          local linenr, colnr, level, name, description, reference = utils.unpack6(item)
          local charnr = lsp_utils.byte_offset_to_char_offset(colnr - 1, buf_lines[linenr])
          diagnostics[idx] = {
            severity = VINT_LEVEL_TO_LSP_SEVERITY[level] or DiagnosticSeverity.Error,
            range = {
              start = { line = linenr - 1, character = charnr },
              ['end'] = { line = linenr - 1, character = charnr + 1 },
            },
            code = name,
            message = string.format('%s (see %s)', description, reference),
          }
        end

        vserver.send_message('textDocument/publishDiagnostics', {
          uri = buf_uri,
          version = buf_version,
          diagnostics = diagnostics,
        })
      end
      return {
        ['textDocument/didOpen'] = function(reply, _, params, _, vserver)
          trigger_diagnostics(params.textDocument.uri, vserver)
          return reply(nil)
        end,
        ['textDocument/didSave'] = function(reply, _, params, _, vserver)
          trigger_diagnostics(params.textDocument.uri, vserver)
          return reply(nil)
        end,
      }
    end)();
  };
})
