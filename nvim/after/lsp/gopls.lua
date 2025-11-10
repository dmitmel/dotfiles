---@type dotfiles.lsp.Config
return {
  cmd = { 'gopls' },
  filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },

  build_settings = function(ctx) ctx.settings:merge(ctx.new_settings:pick({ 'gopls' })) end,
}
