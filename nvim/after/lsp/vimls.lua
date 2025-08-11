-- <https://github.com/neovim/nvim-lspconfig/blob/master/lsp/vimls.lua>
-- <https://github.com/iamcco/coc-vimlsp/blob/master/src/index.ts>

local utils = require('dotfiles.utils')

---@type dotfiles.lsp.Config
return {
  cmd = { 'vim-language-server', '--stdio' },
  filetypes = { 'vim' },

  init_options = {
    isNeovim = utils.has('nvim'),
    suggest = {
      fromVimruntime = true,
      fromRuntimepath = true,
    },
    diagnostic = {
      enable = true,
    },
  },

  build_settings = function(_ctx)
    -- Just do nothing. This server supports configuration only via `init_options`.
  end,

  before_init = function(init_params) ---@param init_params lsp.InitializeParams
    local init_opts = init_params.initializationOptions --[[@as table]]
    init_opts.iskeyword = vim.api.nvim_get_option_value('iskeyword', { filetype = 'vim' })
    init_opts.vimruntime = vim.env.VIMRUNTIME
    init_opts.runtimepath = vim.o.runtimepath
  end,
}
