-- <https://github.com/neoclide/coc-html/blob/master/src/index.ts>
-- <https://github.com/microsoft/vscode/blob/main/extensions/html-language-features/server/src/htmlServer.ts>

local lsp_ignition = require('dotfiles.lsp.ignition')
local lspconfig_utils = require('lspconfig.util')
local lsp_utils = require('dotfiles.lsp.utils')

local function find_exe()
  for _, exe in ipairs({
    'vscode-html-language-server', -- <https://github.com/hrsh7th/vscode-langservers-extracted>
    'vscode-html-languageserver', -- <https://archlinux.org/packages/community/any/vscode-html-languageserver/>
  }) do
    if vim.fn.executable(exe) ~= 0 then
      return { exe }
    end
  end
  if lsp_utils.VSCODE_INSTALL_PATH then
    local path = lsp_utils.VSCODE_INSTALL_PATH
      .. '/extensions/html-language-features/server/dist/node/htmlServerMain.js'
    if vim.fn.filereadable(path) ~= 0 then
      return { 'node', path }
    end
  end
  return { 'vscode-html-language-server' } -- fallback
end

-- <https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/server_configurations/html.lua>
lsp_ignition.setup_config('htmlls', {
  cmd = vim.list_extend(find_exe(), { '--stdio' }),
  filetypes = { 'html', 'handlebars', 'htmldjango', 'blade' },
  -- root_dir = lspconfig_utils.root_pattern('package.json');
  single_file_support = true,
  completion_menu_label = 'HTML',

  init_options = {
    embeddedLanguages = {
      css = true,
      javascript = true,
    },
    configurationSection = { 'html', 'css', 'javascript' },
  },

  settings_scopes = { 'html', 'css', 'javascript' },
  settings = {
    html = {
      format = {
        enable = false,
      },
    },
    javascript = {
      format = {
        enable = false,
      },
    },
    css = {
      format = {
        enable = false,
      },
    },
  },
})
