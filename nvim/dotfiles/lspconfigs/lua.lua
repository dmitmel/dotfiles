-- <https://github.com/sumneko/vscode-lua/blob/master/client/src/languageserver.ts>
-- <https://github.com/sumneko/vscode-lua/blob/master/setting/schema.json>

local lsp_ignition = require('dotfiles.lsp.ignition')
local utils = require('dotfiles.utils')
local utils_vim = require('dotfiles.utils.vim')
local vim_uri = require('vim.uri')
local lsp_utils = require('dotfiles.lsp.utils')

local server_install_dir, server_bin_platform
if utils_vim.has('macunix') then
  server_install_dir = '/usr/local/opt/lua-language-server/libexec'
  server_bin_platform = 'macOS'
else
  server_install_dir = '/usr/lib/lua-language-server'
  server_bin_platform = 'Linux'
end

local data_path = vim.call('dotfiles#paths#xdg_cache_home') .. '/lua-language-server'
-- <https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/server_configurations/sumneko_lua.lua>
local lua_config = lsp_ignition.setup_config('sumneko_lua', {
  cmd = {
    server_install_dir .. '/bin/' .. server_bin_platform .. '/lua-language-server',
    '-E',
    server_install_dir .. '/main.lua',
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
    -- Yep, that's right, the library list is resolved at runtime, no need for
    -- configurations!
    local cfg_package_path = {}
    local cfg_libraries = {}

    -- <https://github.com/neovim/neovim/blob/v0.5.0/src/nvim/lua/vim.lua#L56-L85>
    -- <https://github.com/neovim/neovim/commit/c60c7375f5754eea2a4209cc6441e70b2bb44f14#diff-a8fd4e44d96101de6e4453a16811a686ce91e33e4767af7666481edb338d0744>
    -- <https://github.com/folke/lua-dev.nvim/blob/8c6a6e32525905a4ca0b74ca0ccd111ef0a6a49f/lua/lua-dev/sumneko.lua#L5-L52>
    local pc = utils.nice_package_config
    for _, rtp_dir in ipairs(vim.api.nvim_list_runtime_paths()) do
      local lua_dir = rtp_dir .. pc.dir_sep .. 'lua'
      if utils_vim.is_truthy(vim.fn.isdirectory(lua_dir)) then
        -- TODO: Refine this check
        if not (root_dir and vim.startswith(lua_dir, root_dir)) then
          -- NOTE: rtp_dir must be used here and not lua_dir!
          cfg_libraries[rtp_dir] = true
        end
        -- table.insert(cfg_package_path, lua_dir .. pc.dir_sep .. pc.template_char .. '.lua')
        -- table.insert(cfg_package_path, lua_dir .. pc.dir_sep .. pc.template_char .. pc.dir_sep .. 'init.lua')
      end
    end
    -- The Vim-specific paths are tried before Lua's `package.path` stuff, and
    -- `init.lua` must come after literal files.
    table.insert(cfg_package_path, 'lua' .. pc.dir_sep .. pc.template_char .. '.lua')
    table.insert(
      cfg_package_path,
      'lua' .. pc.dir_sep .. pc.template_char .. pc.dir_sep .. 'init.lua'
    )
    for path in vim.gsplit(package.path, pc.path_list_sep) do
      table.insert(cfg_package_path, path)
    end

    final_config.settings.Lua.runtime.path = cfg_package_path
    final_config.settings.Lua.workspace.library = cfg_libraries
  end,
})

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
        })

        vim.fn.chansend(job, buf_lines)
        vim.fn.chanclose(job, 'stdin')
      end,
    },
  },
})
