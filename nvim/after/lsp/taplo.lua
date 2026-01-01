---@type dotfiles.lsp.Config
return {
  cmd = { 'taplo', 'lsp', 'stdio' },
  filetypes = { 'toml' },
  root_markers = { '.taplo.toml', 'taplo.toml', '.git' },
  build_settings = function(ctx) ctx.settings:merge(ctx.new_settings:pick({ 'evenBetterToml' })) end,
}
