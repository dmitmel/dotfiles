-- <https://github.com/sumneko/vscode-lua/blob/master/client/src/languageserver.ts>
-- <https://github.com/sumneko/vscode-lua/blob/master/setting/schema.json>

local lspconfig = require('lspconfig')
local utils = require('dotfiles.utils')
local utils_vim = require('dotfiles.utils.vim')

local data_path = vim.call('dotfiles#paths#xdg_cache_home') .. '/lua-language-server'
lspconfig['sumneko_lua'].setup({
  cmd = {
    '/usr/lib/lua-language-server/bin/Linux/lua-language-server', '-E', '/usr/lib/lua-language-server/main.lua',
    '--logpath=' .. data_path .. '/log',
    '--metapath=' .. data_path .. '/meta',
  };

  completion_menu_label = 'Lua';

  settings_scopes = {'Lua'};
  settings = {
    Lua = {
      runtime = {
        version = 'LuaJIT';
        path = vim.NIL;
      };
      workspace = {
        library = vim.NIL;
      };
      diagnostics = {
        globals = {
          -- Vim configs
          'vim',
          -- Hammerspoon configs
          'hs',
          -- Neovim's testing framework
          'describe', 'it', 'setup', 'teardown', 'before_each', 'after_each', 'pending',
        };
        disable = {'empty-block'};
        libraryFiles = 'Opened';
      };
      completion = {
        workspaceWord = false;
        showWord = 'Disable';
        callSnippet = 'Replace';
      };
    };
  };

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
    table.insert(cfg_package_path, 'lua' .. pc.dir_sep .. pc.template_char .. pc.dir_sep .. 'init.lua')
    for path in vim.gsplit(package.path, pc.path_list_sep) do
      table.insert(cfg_package_path, path)
    end

    final_config.settings.Lua.runtime.path = cfg_package_path
    final_config.settings.Lua.workspace.library = cfg_libraries
  end;
})
