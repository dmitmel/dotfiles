-- <https://github.com/neoclide/coc-json/blob/master/src/index.ts>
-- <https://github.com/microsoft/vscode/blob/main/extensions/json-language-features/client/src/jsonClient.ts>

local lsp_global_settings = require('dotfiles.lsp.global_settings')
local lsp_utils = require('dotfiles.lsp.utils')
local lsp_ignition = require('dotfiles.lsp.ignition')
local vim_uri = require('vim.uri')

local function find_exe()
  for _, exe in ipairs({
    'vscode-json-language-server', -- <https://github.com/hrsh7th/vscode-langservers-extracted>
    'vscode-json-languageserver', -- <https://archlinux.org/packages/community/any/vscode-json-languageserver/>
  }) do
    if vim.fn.executable(exe) ~= 0 then
      return { exe }
    end
  end
  if lsp_utils.VSCODE_INSTALL_PATH then
    local path = lsp_utils.VSCODE_INSTALL_PATH
      .. '/extensions/json-language-features/server/dist/node/jsonServerMain.js'
    if vim.fn.filereadable(path) ~= 0 then
      return { 'node', path }
    end
  end
  return { 'vscode-json-language-server' } -- fallback
end

local json_filetypes = { 'json', 'jsonc', 'json5' }
-- <https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/server_configurations/jsonls.lua>
lsp_ignition.setup_config('jsonls', {
  cmd = vim.list_extend(find_exe(), { '--stdio' }),
  filetypes = json_filetypes,
  single_file_support = true,
  completion_menu_label = 'JSON',

  init_options = {
    provideFormatter = false,
    -- handledSchemaProtocols = {'file'};
  },

  settings_scopes = { 'json', 'http' },
  settings = {
    json = {
      format = {
        enable = false,
      },
      schemas = lsp_global_settings.JSON_SCHEMAS_CATALOG,
    },
  },

  handlers = {
    -- <https://github.com/microsoft/vscode/tree/main/extensions/json-language-features/server#item-limit>
    ['json/resultLimitReached'] = lsp_utils.wrap_handler_errors(function(params, ctx, _)
      lsp_utils.client_notify(ctx.client_id, params[1], vim.log.levels.WARN)
    end),

    ['vscode/content'] = lsp_utils.wrap_handler_errors(function(params, ctx, _)
      lsp_utils.client_notify(
        ctx.client_id,
        string.format("Can't handle an unknown schema URL: %s", params[1]),
        vim.log.levels.ERROR
      )
      return '{}'
    end),
  },
})

lsp_ignition.setup_config('jqfmt', {
  filetypes = json_filetypes,
  -- root_dir = jsonls_config.root_dir;
  single_file_support = true,

  virtual_server = {
    capabilities = {
      documentFormattingProvider = true,
    },
    handlers = {
      ['textDocument/formatting'] = function(reply, _, params, _, vserver)
        local buf_uri = params.textDocument.uri
        local bufnr = vim_uri.uri_to_bufnr(buf_uri)
        assert(vim.api.nvim_buf_is_loaded(bufnr))
        local buf_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)

        local shiftwidth = vim.api.nvim_buf_call(bufnr, function()
          return vim.fn.shiftwidth()
        end)

        local jq_args = { 'jq' }
        if vim.api.nvim_buf_get_option(bufnr, 'expandtab') then
          table.insert(jq_args, '--indent')
          table.insert(jq_args, shiftwidth)
        else
          table.insert(jq_args, '--tab')
        end

        local fmt_lines = vim.fn.systemlist(jq_args, buf_lines)
        if vim.v.shell_error ~= 0 then
          return reply(nil, nil)
        end

        local any_changes, common_lines_from_start, common_lines_from_end =
          lsp_utils.simple_line_diff(
            buf_lines,
            fmt_lines
          )
        if not any_changes then
          return reply(nil, nil)
        end

        local changed_lines = {}
        for i = common_lines_from_start + 1, #fmt_lines - common_lines_from_end do
          changed_lines[#changed_lines + 1] = fmt_lines[i] .. '\n'
        end
        local one_big_text_edit = {
          range = {
            start = { line = common_lines_from_start, character = 0 },
            ['end'] = { line = #buf_lines - common_lines_from_end, character = 0 },
          },
          newText = table.concat(changed_lines),
        }
        return reply(nil, { one_big_text_edit })
      end,
    },
  },
})
