-- <https://github.com/neovim/nvim-lspconfig/blob/master/lsp/jsonls.lua>
-- <https://github.com/neoclide/coc-json/blob/master/src/index.ts>
-- <https://github.com/microsoft/vscode/blob/main/extensions/json-language-features/client/src/jsonClient.ts>

local lsp_extras = require('dotfiles.lsp_extras')

---@type dotfiles.lsp.Config
local config = {
  cmd = lsp_extras.find_vscode_server({
    npm_exe = 'vscode-json-language-server',
    archlinux_exe = 'vscode-json-languageserver',
    vscode_script = 'extensions/json-language-features/server/dist/node/jsonServerMain.js',
    args = { '--stdio' },
  }),
  filetypes = { 'json', 'jsonc', 'json5' },

  init_options = {
    provideFormatter = false,
  },

  settings = {
    json = { schemas = {} },
  },

  lazy_settings = function(cfg)
    vim.list_extend(cfg.settings['json']['schemas'], require('schemastore').json.schemas())
  end,
}

return config
