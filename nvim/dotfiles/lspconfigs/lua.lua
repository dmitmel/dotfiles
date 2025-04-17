-- <https://github.com/sumneko/vscode-lua/blob/master/client/src/languageserver.ts>
-- <https://github.com/sumneko/vscode-lua/blob/master/setting/schema.json>

local lsp_ignition = require('dotfiles.lsp.ignition')
local lsp_dummy_entry_plug = require('dotfiles.lsp.dummy_entry_plug')
local utils = require('dotfiles.utils')
local vim_uri = require('vim.uri')
local lsp_utils = require('dotfiles.lsp.utils')
local nvim_lua_dev = require('dotfiles.lsp.nvim_lua_dev')

local data_path = vim.call('dotfiles#paths#xdg_cache_home') .. '/lua-language-server'
-- <https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/server_configurations/sumneko_lua.lua>
local lua_config = lsp_ignition.setup_config('sumneko_lua', {
  cmd = {
    'lua-language-server',
    '--logpath=' .. data_path .. '/log',
    '--metapath=' .. data_path .. '/meta',
  },
  filetypes = { 'lua' },
  single_file_support = true,

  completion_menu_label = 'Lua',

  settings_scopes = { 'Lua' },
  settings = {
    Lua = {
      telemetry = {
        enable = true,
      },
      runtime = {
        version = 'LuaJIT',
        path = vim.NIL,
      },
      workspace = {
        library = vim.NIL,
      },
      diagnostics = {
        globals = {
          -- Vim configs
          'vim',
          -- Hammerspoon configs
          'hs',
          -- Neovim's testing framework
          'describe',
          'it',
          'setup',
          'teardown',
          'before_each',
          'after_each',
          'pending',
        },
        disable = { 'empty-block' },
        libraryFiles = 'Opened',
      },
      completion = {
        workspaceWord = false,
        showWord = 'Disable',
        callSnippet = 'Replace',
      },
    },
  },

  on_new_config = function(final_config, root_dir)
    local extra_settings = nvim_lua_dev.lua_ls_settings_for_vim(root_dir)
    final_config.settings.Lua.runtime.path = extra_settings.package_path
    final_config.settings.Lua.workspace.library = extra_settings.libraries
  end,
})

-- lsp_dummy_entry_plug.setup_formatter('stylua', {
--   filetypes = lua_config.filetypes,
--   root_dir = lua_config.root_dir,
-- })

lsp_ignition.setup_config('stylua', {
  filetypes = lua_config.filetypes,
  root_dir = lua_config.root_dir,
  single_file_support = true,

  virtual_server = {
    capabilities = {
      documentFormattingProvider = true,
      documentRangeFormattingProvider = true, -- TODO
    },
    handlers = {
      ['textDocument/formatting'] = function(reply, _, params, _, vserver)
        local buf_uri = params.textDocument.uri
        local bufnr = vim_uri.uri_to_bufnr(buf_uri)
        assert(vim.api.nvim_buf_is_loaded(bufnr))
        local buf_path = utils.uri_maybe_to_fname(buf_uri)
        local buf_root_dir = vserver.root_dir or vim.fn.getcwd()

        local buf_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)
        local fmt_lines = nil

        local cmd = { 'stylua', '-', '--search-parent-directories' }
        if buf_path then
          table.insert(cmd, '--stdin-filepath=' .. buf_path)
        end
        local err_output = nil

        local job = vim.fn.jobstart(cmd, {
          cwd = buf_root_dir,
          stdin = 'pipe',
          stdout_buffered = true,
          on_stdout = function(_, lines, _)
            fmt_lines = lines
          end,
          stderr_buffered = true,
          on_stderr = function(_, lines, _)
            if lines[#lines] == '' then
              lines[#lines] = nil
            end
            err_output = table.concat(lines, '\n')
          end,

          on_exit = function(_, code, _)
            if code ~= 0 then
              reply(err_output, nil)
              return
            end

            if fmt_lines[#fmt_lines] == '' then
              fmt_lines[#fmt_lines] = nil
            end

            local any_changes, common_lines_from_start, common_lines_from_end =
              lsp_utils.simple_line_diff(buf_lines, fmt_lines)
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
        })

        vim.fn.chansend(job, buf_lines)
        vim.fn.chanclose(job, 'stdin')
      end,
    },
  },
})
