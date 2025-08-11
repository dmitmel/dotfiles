-- <https://github.com/neovim/nvim-lspconfig/blob/master/lsp/lua_ls.lua>
-- <https://github.com/sumneko/vscode-lua/blob/master/client/src/languageserver.ts>
-- <https://github.com/sumneko/vscode-lua/blob/master/setting/schema.json>

---@type dotfiles.lsp.Config
return {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = {
    '.luarc.json',
    '.luarc.jsonc',
    '.luacheckrc',
    '.stylua.toml',
    'stylua.toml',
    '.git',
  },

  build_settings = function(ctx)
    ctx.settings:merge(ctx.new_settings:pick({ 'Lua', 'files' }))

    -- NOTE: <https://github.com/LuaLS/lua-language-server/wiki/FAQ#why-are-there-two-workspacesprogress-bars>
    -- NOTE: <https://github.com/LuaLS/lua-language-server/issues/1596#issuecomment-1260881130>
    if ctx.trigger == 'server_request' and ctx.step == 'generated' and ctx.scope_uri ~= nil then
      local workspace_dir = vim.uri_to_fname(ctx.scope_uri)
      ctx.settings:merge_defaults({
        Lua = require('dotfiles.nvim_lua_dev').make_settings('lua_ls', workspace_dir),
      })
    end
  end,
}
