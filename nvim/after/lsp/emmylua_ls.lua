-- <https://github.com/neovim/nvim-lspconfig/blob/master/lsp/emmylua_ls.lua>

---@type dotfiles.lsp.Config
return {
  cmd = { 'emmylua_ls' },
  filetypes = { 'lua' },
  root_markers = { '.luarc.json', '.emmyrc.json', '.luacheckrc', '.git' },

  build_settings = function(ctx)
    ctx.settings:merge(ctx.new_settings:pick({ 'Lua' }))

    if ctx.trigger == 'server_request' and ctx.step == 'generated' and ctx.client then
      ctx.settings:merge_defaults({
        Lua = require('dotfiles.nvim_lua_dev').make_settings('emmylua_ls', ctx.client.root_dir),
      })
    end
  end,
}
