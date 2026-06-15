-- <https://github.com/neovim/nvim-lspconfig/blob/master/lsp/stylua.lua>

---@type dotfiles.lsp.Config
return {
  cmd = { 'stylua', '--lsp', '--search-parent-directories' },
  filetypes = { 'lua', 'luau' },
  root_markers = { '.stylua.toml', 'stylua.toml', '.editorconfig', '.git' },
  init_options = {
    respect_editor_formatting_options = true,
  },
}
